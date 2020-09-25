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

#!/bin/bash

load '../bats_libs/bats-support/load'
load '../bats_libs/bats-assert/load'
load '../bats_libs/bats-file/load'

function setup_move2kube() {
  DATA_DIR="data"
  echo "Using data from "$DATA_DIR
  TEST_TEMP_DIR="$(temp_make)"
  echo "Outputting data to "$TEST_TEMP_DIR
}

function teardown_move2kube() {
  temp_del "$TEST_TEMP_DIR"
}

# Version info will de deleted from files before compare
function compare_yamls() { # arguments : file1, file2
  #yq delete -i $2 versioninfo
  #yq delete $1 versioninfo | yq compare - $2
  yq compare $1 $2 
}

# Version info will de deleted from files before compare
function compare_yamlfiles() { # arguments : file folder1, folder2
  relpath=$(echo "$1" | sed 's@'"$2"'@@')
  compare_yamls $2/$relpath $3/$relpath
}

function compare_folders() { # arguments : dir1, dir2
  # Makes sure all file names are present in both
  diff <(find $1 -type f -exec echo {} \; | sort -k 1 | sed 's@'"$1"'@@' ) <(find $2 -type f -exec echo {} \; | sort -k 1 | sed 's@'"$2"'@@')
  # Makes sure all non yaml files match exactly
  diff <(find $1 -type f -not -name "*.yml" -not -name "*.yaml" -exec md5sum {} + | sort -k 2 | sed 's/ .*\// /') <(find $2 -type f -not -name "*.yml" -not -name "*.yaml" -exec md5sum {} + | sort -k 2 | sed 's/ .*\// /')
  # Makes sure all yaml files match without the version
  find $1 -type f -name "*.yml" -o -name "*.yaml" -print | while read file; do compare_yamlfiles "$file" $1 $2; done
}