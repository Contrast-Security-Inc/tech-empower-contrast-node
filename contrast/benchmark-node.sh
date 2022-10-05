#!/bin/bash
source ./benchmark-variables.sh

set -e

cd "${0%/*}"

# Use files in the script directory by default
AGENT_FILE=${1-node-contrast.tgz}

if [[ $(basename -- "$AGENT_FILE") != "node-contrast.tgz" ]];
    then echo "First argument must be a path to node-contrast.tgz" && exit 1;
fi;

if [[ ! -f $AGENT_FILE ]];
    then echo "Could not find $AGENT_FILE" && exit 1;
fi;

# Copy files into correct place
./copy-files.sh JavaScript $AGENT_FILE

# Update dockerfiles to use correct package
FILES_TO_MODIFY=($(grep -HRl "# Start Contrast Additions for v5 node-agent" ../frameworks/JavaScript))
if [[ ${FILES_TO_MODIFY[@]} ]]; then
  for i in "${FILES_TO_MODIFY[@]}"
  do 
    awk '/Additions for v5 node-agent/ { print "# Start Contrast Additions for v4 node-agent"; next }1' ${i} > ${i}.bak && mv ${i}.bak ${i}
  done
  grep -r 'RUN cd .\/node_modules\/@contrast\/mono-workspace' ../frameworks/JavaScript -l | xargs -I '{}' -n 1 sed -i.bak "/RUN cd .\/node_modules\/@contrast\/mono-workspace/d" {} && ls -d ../frameworks/JavaScript/*/*.bak | xargs -n 1 rm
  grep -r @contrast/mono-workspace/protect-agent ../frameworks/JavaScript -l | xargs -I '{}' -n 1 sed -i.bak "s#@contrast/mono-workspace/protect-agent#@contrast/agent#" {} && ls -d ../frameworks/JavaScript/*/*.bak | xargs -n 1 rm
fi

# Start contrast-service
./start-contrast-service.sh

# Run tests
../tfb --tag $TAG --test-lang JavaScript --type fortune --duration $DURATION --concurrency-levels $CONCURRENCY_LEVELS

# Stop contrast-service container
docker stop contrast-service
