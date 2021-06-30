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

#!/usr/bin/env bats

load test_helpers

function setup() {
    setup_move2kube
}

function teardown() {
    teardown_move2kube
}

@test "move2kube" {
  run move2kube
  [ "$status" = 0 ]
}

@test "move2kube version" {
    run move2kube version
    [ "$status" = 0 ]
}

@test "move2kube collect" {
    run move2kube collect -h
    [ "$status" = 0 ]
}

@test "move2kube plan" {
    run move2kube plan -h
    [ "$status" = 0 ]
}

@test "move2kube transform" {
    run move2kube transform -h
    [ "$status" = 0 ]
}


