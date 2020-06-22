#!/bin/sh

set -x

bump() {
  BRANCH="$1"
  if [ -z "$BRANCH" ]; then
    echo "usage: $0 <branch>"
    exit 1
  fi

  if git status | grep -q 'modified:'; then
    echo "modified files detected, commit or stash and rerun"
    exit 2
  fi

  git checkout "$BRANCH"
  git pull "$BRANCH"

  DATE=$(date +%Y%m%d.1)

  sed -i "s/ENV BUMP .*/ENV BUMP $DATE/" Dockerfile
  git stage Dockerfile
  git commit -m "bump $DATE"
  git push origin "$BRANCH"
}

bump master
