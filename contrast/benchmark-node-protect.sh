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
./copy-files.sh node-protect $AGENT_FILE

# Update dockerfiles to use correct package
FILES_TO_MODIFY=($(grep -HRl "/node-contrast.tgz" ../frameworks/JavaScript))
for i in "${FILES_TO_MODIFY[@]}"
 do 
  awk '/npm install .\/node-contrast/ { print; print "RUN pushd ./node_modules/@contrast/mono-workspace && npm install--ignore-scripts--omit-dev && popd"; next }1' ${i} > ${i}.bak && mv ${i}.bak ${i}
done
grep -r @contrast/agent ../frameworks/JavaScript -l | xargs -I '{}' -n 1 sed -i.bak "s#@contrast/agent#@contrast/mono-workspace/protect-agent#" {} && ls -d ../frameworks/JavaScript/*/*.bak | xargs -n 1 rm

# Start contrast-service
./start-contrast-service.sh

# Run tests
../tfb --tag contrast-unattached contrast-off contrast-protect --test-lang JavaScript --type fortune --duration $DURATION --concurrency-levels $CONCURRENCY_LEVELS

# Stop contrast-service container
docker stop contrast-service
