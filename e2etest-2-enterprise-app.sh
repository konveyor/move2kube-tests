#!/usr/bin/env bash

# https://kind.sigs.k8s.io/docs/user/ingress/
# https://kind.sigs.k8s.io/docs/user/local-registry/

reg_name='kind-registry'
reg_port='5001'

echo 'start'
echo 'some info'
kind version
kubectl version
kubectl get pods
move2kube version -l

echo 'delete any existing clusters'
kind delete cluster
kind get clusters

echo 'check if local container registry is running'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
    echo 'start local container registry'
    docker run -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" registry:2
    docker ps -a
fi

echo 'start a new cluster with the proper config'
kind create cluster --config=config.yaml
echo 'apply the ingress controller'
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
echo 'check if the local container registry is connected to the cluster'
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
    echo 'connect the local container registry to the cluster'
    docker network connect "kind" "${reg_name}"
fi

echo 'wait for ingress controller to come online'
sleep 2
until kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s; do sleep 1; done
echo $?

echo 'after ingress controller comes online'
kubectl get pods
kubectl get pods --namespace ingress-nginx
echo 'before transforming using move2kube'
rm -rf temp && mkdir temp
cd temp || exit
curl https://move2kube.konveyor.io/scripts/download.sh | bash -s -- -r move2kube-demos -d samples/enterprise-app/src
curl https://move2kube.konveyor.io/scripts/download.sh | bash -s -- -r move2kube-demos -d samples/enterprise-app/database
kubectl apply -f database
ls
move2kube plan -s src || exit
move2kube transform --config ../e2etest-2-enterprise-app-m2kconfig.yaml --qa-skip || exit
ls
ls myproject
cd myproject/scripts || exit
echo 'before building images generated by move2kube'
./buildimages.sh
echo 'before pushing images generated by move2kube'
./pushimages.sh
cd ..
echo 'before applying K8s yamls generated by move2kube'
kubectl apply -f deploy/yamls
sleep 2
kubectl get all
echo 'wait for pods to start'
kubectl wait --for=condition=ready pod --timeout=90s --selector=move2kube.konveyor.io/service=database || exit
kubectl get pods
echo 'after database pods come online'
kubectl wait --for=condition=ready pod --timeout=90s --selector=move2kube.konveyor.io/service=frontend || exit
kubectl get pods
echo 'after frontend pods come online'
kubectl wait --for=condition=ready pod --timeout=90s --selector=move2kube.konveyor.io/service=gateway || exit
kubectl get pods
echo 'after gateway pods come online'
kubectl wait --for=condition=ready pod --timeout=90s --selector=move2kube.konveyor.io/service=inventory || exit
kubectl get pods
echo 'after inventory pods come online'
kubectl wait --for=condition=ready pod --timeout=90s --selector=move2kube.konveyor.io/service=orders || exit
kubectl get pods
echo 'after orders pods come online'
kubectl wait --for=condition=ready pod --timeout=90s --selector=move2kube.konveyor.io/service=customers || exit
kubectl get pods
echo 'after customers pods come online'
echo 'before ingress gets assigned an address'
sleep 2
until kubectl wait ingress/myproject --for=jsonpath='status.loadBalancer.ingress[0].hostname'=localhost; do sleep 1; done
kubectl get ingress
echo 'after ingress gets assigned an address'
echo 'before deploying to the kind cluster'

function check_url() {
    local status_code
    status_code="$(curl -LI "$1" -o /dev/null -w '%{http_code}\n' -s)"
    if [[ "$status_code" == '200' ]]; then
        echo ✅ "$status_code" "$1"
        return 0
    fi
    echo ❌ "$status_code" "$1"
    return 1
}

function all_tests() {
    echo 'Running End-to-End tests:'
    local passed=0
    check_url localhost/ || passed=1
    return "$passed"
}

function main() {
    if all_tests; then
        echo '✅ All tests passed!'
    else
        echo '❌ Some tests failed!'
    fi
}

main | tee -a results.txt
cd ../..
