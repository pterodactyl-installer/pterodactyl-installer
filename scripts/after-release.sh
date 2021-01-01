#!/bin/bash

output() {
    echo "- $1"
}

output "Reverting changes after release"

# install-panel.sh
sed -i "s/.*GITHUB_SOURCE=.*/GITHUB_SOURCE=\"master\"/" install-panel.sh
sed -i "s/.*SCRIPT_RELEASE=.*/SCRIPT_RELEASE=\"canary\"/" install-panel.sh

# install-wings.sh
sed -i "s/.*GITHUB_SOURCE=.*/GITHUB_SOURCE=\"master\"/" install-wings.sh
sed -i "s/.*SCRIPT_RELEASE=.*/SCRIPT_RELEASE=\"canary\"/" install-wings.sh

output "Commit changes"

git add .
git commit -S -m "Set version for development"
git push

output "Relevant changes reverted"
