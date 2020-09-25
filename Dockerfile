FROM quay.io/konveyor/move2kube:latest 
RUN dnf group install "Development Tools" -y
RUN yum install -y npm make git expect
RUN npm install -g bats
RUN curl -L https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64  --output /bin/yq
RUN chmod +x /bin/yq
WORKDIR /wksps
VOLUME ["/wksps"]