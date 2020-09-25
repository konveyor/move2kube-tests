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

@test "plan_compose" {
  run move2kube plan -s $DATA_DIR/source/compose -p $TEST_TEMP_DIR/m2k.plan
  echo "status = ${status}"
  echo "output = ${output}"
  [ "$status" = 0 ]
  run compare_yamls $DATA_DIR/plan/compose/m2k.plan $TEST_TEMP_DIR/m2k.plan
  echo "status = ${status}"
  echo "output = ${output}"
  [ -z "$output" ]
}