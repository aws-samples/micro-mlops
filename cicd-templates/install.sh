#!/bin/bash

#git clone https://gitlab.cloudstart-metaverse.com/mlops-aws/gitlab-ci/cicd-templates.git
#git pull

HOOK_DIR=/var/opt/gitlab/gitaly/custom_hooks/pre-receive.d
mkdir $HOOK_DIR -p
cp -r custom_hooks/pre-receive.d/. $HOOK_DIR/
chown git:git $HOOK_DIR/.
