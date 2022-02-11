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
mkdir temp
cd temp
curl https://move2kube.konveyor.io/scripts/download.sh | bash -s -- -d samples/language-platforms -r move2kube-demos
ls
move2kube plan -s language-platforms
move2kube transform --config ../m2kconfig.yaml --qa-skip
ls
ls myproject
cd myproject/scripts
echo 'before building images generated by move2kube'
./builddockerimages.sh
echo 'before pushing images generated by move2kube'
./pushimages.sh
cd ..
echo 'before applying K8s yamls generated by move2kube'
kubectl apply -f deploy/yamls
sleep 2
kubectl get all
echo 'wait for pods to start'
kubectl wait --for=condition=ready pod --selector=move2kube.konveyor.io/service=golang --timeout=90s
kubectl get pods
echo 'after golang pods comes online'
kubectl wait --for=condition=ready pod --selector=move2kube.konveyor.io/service=nodejs --timeout=90s
kubectl get pods
echo 'after nodejs pods comes online'
kubectl wait --for=condition=ready pod --selector=move2kube.konveyor.io/service=ruby --timeout=90s
kubectl get pods
echo 'after ruby pods comes online'
kubectl wait --for=condition=ready pod --selector=move2kube.konveyor.io/service=rust --timeout=90s
kubectl get pods
echo 'after rust pods comes online'
kubectl wait --for=condition=ready pod --selector=move2kube.konveyor.io/service=test-github-actions-3-python --timeout=90s
kubectl get pods
echo 'after python pods comes online'
echo 'before ingress gets assigned an address'
sleep 2
until kubectl wait ingress/myproject --for=jsonpath='status.loadBalancer.ingress[0].hostname'=localhost; do sleep 1; done
kubectl get ingress
echo 'after ingress gets assigned an address'
echo 'before testing language platforms deployment'
curl -i localhost/nodejs | tee -a results.txt
echo -e '\n------------------' | tee -a results.txt
sleep 2
curl -i localhost/golang | tee -a results.txt
echo -e '\n------------------' | tee -a results.txt
sleep 2
curl -i localhost/rust | tee -a results.txt
echo -e '\n------------------' | tee -a results.txt
sleep 2
curl -i localhost/ruby | tee -a results.txt
echo -e '\n------------------' | tee -a results.txt
sleep 2
curl -i localhost/python | tee -a results.txt
echo -e '\n------------------' | tee -a results.txt
echo 'after testing language platforms deployment'
cat results.txt
cd ../..
