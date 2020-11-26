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

MOVE2KUBETEST_IMAGE := "move2kube-test"

GIT_COMMIT = $(shell git rev-parse HEAD)
GIT_SHA    = $(shell git rev-parse --short HEAD)
GIT_TAG    = $(shell git describe --tags --abbrev=0 --exact-match 2>/dev/null)
GIT_DIRTY  = $(shell test -n "`git status --porcelain`" && echo "dirty" || echo "clean")

ifeq ($(VERSION),)
	VERSION = ${GIT_TAG}
endif
ifeq ($(VERSION),)
	VERSION = latest
endif

# HELP
# This will output the help for each task
.PHONY: help
help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: test-docker
test-docker: image ## Run integration tests in container
	docker run \
		-v $(CURDIR):/wksps/ \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(MOVE2KUBETEST_IMAGE):${VERSION} make test-local TESTPATH=$(TESTPATH)

.PHONY: test-local
test-local:  ## Run local integration tests
	BATSLIB_TEMP_PRESERVE_ON_FAILURE=1 bats -t tests/$(TESTPATH)

.PHONY: image
image:
	docker build -t $(MOVE2KUBETEST_IMAGE):${VERSION} --build-arg VERSION=${VERSION} .
