#   Copyright IBM Corporation 2020
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

ARG VERSION=latest
FROM quay.io/konveyor/move2kube:${VERSION} as move2kube
RUN dnf group install "Development Tools" -y \
    && dnf install -y npm make git expect findutils \
    && dnf clean all \
    && rm -rf /var/cache/yum
RUN npm install -g bats
RUN curl -L https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64  --output /bin/yq
RUN chmod +x /bin/yq
VOLUME ["/workspace"]
#"/var/run/docker.sock" needs to be mounted for CNB containerization to be used.
# Start app
WORKDIR /workspace
CMD make test-local
