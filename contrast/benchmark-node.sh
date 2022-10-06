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
echo "Will query for files for modification"
  grep -r node-agent-v5 ../frameworks/JavaScript -l | xargs -I '{}' -n 1 sed -i.bak "s#node-agent-v5#node-agent-v4#" {} && ls -d ../frameworks/JavaScript/*/*.bak | xargs -n 1 rm
  echo "Version comment modified"
  grep -r node_modules/@contrast/mono-workspace ../frameworks/JavaScript -l | xargs -I '{}' -n 1 sed -i.bak "/node_modules/d" {} && ls -d ../frameworks/JavaScript/*/*.bak | xargs -n 1 rm
  echo "Unnecessary npm install calls removed"
  grep -r @contrast/mono-workspace/protect-agent ../frameworks/JavaScript -l | xargs -I '{}' -n 1 sed -i.bak "s#@contrast/mono-workspace/protect-agent#@contrast/agent#" {} && ls -d ../frameworks/JavaScript/*/*.bak | xargs -n 1 rm
  echo "Start arguments modified"
echo "V4 modification completed"

# Start contrast-service
./start-contrast-service.sh

# Run tests
../tfb --tag $TAG --test-lang JavaScript --type fortune --duration $DURATION --concurrency-levels $CONCURRENCY_LEVELS

# Stop contrast-service container
docker stop contrast-service
