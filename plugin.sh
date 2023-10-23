#!/bin/bash

set -euo pipefail

# settings:
# APP_NAME: application name (shows in the commit message)
APP_NAME="$PLUGIN_APP_NAME"
# REPO: GitHub repository, e.g. lbogdan/test-test
REPO="$PLUGIN_REPO"
# SSH_KEY: private key with push access to the repository
SSH_KEY="$PLUGIN_SSH_KEY"
# ENV: (optional) environment to deploy to; default: DRONE_DEPLOY_TO
ENV="${PLUGIN_ENV:-$DRONE_DEPLOY_TO}"
# FILE: absolute path of yaml file to update the tag in
FILE="${PLUGIN_FILE/\$ENV/$ENV}"
FILE="${FILE/\$APP/$APP_NAME}"
# GIT_AUTHOR_NAME
# GIT_AUTHOR_EMAIL
# DRONE_TAG
# DRONE_DEPLOY_TO

_git () {
  GIT_SSH_COMMAND="ssh -i $SSH_KEY_FILE -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git "$@"
}

_cleanup () {
  cd - >/dev/null
  if [ -d "$DIR" ]; then
    rm -fr "$DIR"
  fi
  if [ -f "$SSH_KEY_FILE" ]; then
    unlink "$SSH_KEY_FILE"
  fi
}

echo "application: $APP_NAME"
echo "repository:  $REPO"
echo "ssh key:     ${SSH_KEY:0:11}[redacted]"
echo "environment: $ENV"
echo "file:        $FILE"

DIR="$(mktemp -d)"

# write the ssh private key
SSH_KEY_FILE="$(mktemp)"
echo "$SSH_KEY" >"$SSH_KEY_FILE"

# defer cleanup
trap _cleanup EXIT

# clone repository
_git clone "git@github.com:$REPO.git" "$DIR"

cd "$DIR"

# update file
sed -i -E "s/tag: .+/tag: $DRONE_TAG/" "${DIR}$FILE"

# config git user
git config user.email "$GIT_AUTHOR_EMAIL"
git config user.name "$GIT_AUTHOR_NAME"

# commit and push
git diff
git add .
git commit -m "$APP_NAME: deploy $DRONE_TAG to $ENV"
_git push
