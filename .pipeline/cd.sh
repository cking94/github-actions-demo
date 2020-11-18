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

ARTIFACTORY_URL='https://mck.jfrog.io/artifactory'
ARTIFACTORY_PATH="developer-portal-sandbox-generic-local/github-actions-demo"

.pipeline/ci.sh

echo "-------------------------------------------------"
echo " Checking artifactory for next version "
echo "-------------------------------------------------"

BASE_VERSION="$(mckduc get-version \
    --file package.json \
    --pattern '"version": "__VERSION__"')"

NEXT_VERSION="$(mckduc next-version \
    --artifactory-user ${ARTIFACTORY_USER} \
    --artifactory-apikey ${ARTIFACTORY_API_KEY} \
    --artifact-path ${ARTIFACTORY_PATH} \
    --pattern /__VERSION__/ \
    --build-version ${BASE_VERSION} \
    --artifactory-url ${ARTIFACTORY_URL})"

echo "-------------------------------------------------"
echo " Next version is ${NEXT_VERSION} "
echo "-------------------------------------------------"

echo "-------------------------------------------------"
echo " Creating build package"
echo "-------------------------------------------------"
 
ARTIFACT_PATH="github-actions-demo-${NEXT_VERSION}.tgz"
tar -cvzf "${ARTIFACT_PATH}" build manifest* Staticfile

echo "-------------------------------------------------"
echo " Publishing artifacts to Artifactory "
echo "-------------------------------------------------"

ARTIFACTORY_PATH_WITH_VERSION="${ARTIFACTORY_PATH}/${NEXT_VERSION}/"

export JFROG_CLI_OFFER_CONFIG=false

jfrog rt upload \
    "${ARTIFACT_PATH}" \
    "${ARTIFACTORY_PATH_WITH_VERSION}" \
    --recursive=False \
    --url "${ARTIFACTORY_URL}" \
    --user "${ARTIFACTORY_USER}" \
    --password "${ARTIFACTORY_API_KEY}"

echo "-------------------------------------"
echo " Artifactory path ${ARTIFACTORY_PATH_WITH_VERSION}"
echo " Version published ${NEXT_VERSION}"
echo "-------------------------------------"

echo "-------------------------------------------------"
echo " Deploying to staging "
echo "-------------------------------------------------"

PCF_PROD_API=api.sys.ps.west.us.mckesson.com

cf login \
    -a "${PCF_PROD_API}" \
    -u "${PCF_USER}" \
    -p "${PCF_PASSWORD}" \
    -o developer-portal-sandbox-dev \
    -s developer-portal-sandbox-test-space

cf push -f manifest.stg.yml

echo "-------------------------------------------------"
echo " Deploying to production "
echo "-------------------------------------------------"

cf target \
    -o developer-portal-sandbox-dev \
    -s developer-portal-sandbox-dev-space

cf push -f manifest.prd.yml
