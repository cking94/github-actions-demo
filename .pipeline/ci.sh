#!/usr/bin/env bash

set -e

handle_error() {
    echo "${0##*/}: Error occurred on line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

echo "-------------------------------------------------"
echo " Running ${0##*/}"
echo "-------------------------------------------------"

echo "-------------------------------------------------"
echo " Building and Testing"
echo "-------------------------------------------------"

yarn && CI=true yarn test
yarn build

echo "-------------------------------------------------"
echo " SonarQube Analysis"
echo "-------------------------------------------------"

sonarscanner \
    --branch $BRANCH \
    --api-key $SONARQUBE_API_KEY \
    --base-branch main \
    --github-token $GITHUB_TOKEN
