#!/usr/bin/env bash

BRANCH=${BRANCH:-develop}
PREVIEW_ENDPOINT=${PREVIEW_ENDPOINT:-https://atlas-preview.att.com}

if [ "develop" = "$BRANCH" ]; then
  BUILD_ENV="staging"
elif [ "master" = "$BRANCH" ] || [ "main" = "$BRANCH" ]; then
  BUILD_ENV="production"
else
  BUILD_ENV="feature"
fi

copyConfig() {
  if [ -f "$1" ]; then
    cp "$1" "$2"
  fi
}

set -xe

echo $BUILD_BUILDID > public/version.txt

copyConfig ".azure/.env.${BUILD_ENV}" .env.production.local
copyConfig ".azure/staticwebapp.${BUILD_ENV}-config.json" staticwebapp.config.json

if [ "feature" = $BUILD_ENV ]; then
  echo -e "\nPUBLIC_URL=${PREVIEW_ENDPOINT}/${BUILD_REPOSITORY_NAME}--$(echo $BRANCH | sed 's|[\._]|-|g')" >> .env.production.local
fi

yarn run build
