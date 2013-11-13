#!/bin/bash

#
# Monitors a directory for changes since last check.
#
# Bugs:
#   * Manually updated files with same security labels aren't detected
#   * Doesn't pick up deletions as the files don't exist
#

set -e

GATEWAY_HOST="10.66.2.231"
REPO_PATH="$1"
MONITOR_F="/tmp/.nm-$(echo -n "$REPO_PATH" | shasum | awk '{print $1}')"

function find_files {
  if [[ ! -f $MONITOR_F ]]; then
    echo "Warning. First use returns all files."
    FILES=($(find $REPO_PATH/* -type f -name "*-securitylabel.xml" | grep -v ".nexus/trash"))
  else
    FILES=($(find $REPO_PATH/* -type f -cnewer $MONITOR_F -name "*-securitylabel.xml" | grep -v ".nexus/trash"))
  fi

  touch $MONITOR_F
}

function get_xml {
  local result="$(./parsexml.py $1 $2 $3 | tr '\n' ',' | sed 's/,$//g')"
  echo $result
}

find_files

for LABEL in ${FILES[@]}; do
  POM=$(echo $LABEL | sed 's/-securitylabel\.xml$/.pom/') # pom.xml

  # Find primary file
  PACKAGING=$(get_xml "$POM" "packaging" "false")
  ARTIFACT_ID=$(get_xml "$POM" "artifactId" "false")
  GROUP_ID=$(get_xml "$POM" "groupId" "false")
  CLASSIFICATION=$(get_xml "$LABEL" "classification" "true")
  DECORATOR=$(get_xml "$LABEL" "decorator" "true")
  GRPS=$(get_xml "$LABEL" "group" "true")
  COUNTRIES=$(get_xml "$LABEL" "country" "true")

  FILE_EXT=""
  if [[ -z "$PACKAGING" ]]; then
    FILE_EXT="jar"
  elif [[ "nexus-plugin" == "$PACKAGING" ]]; then
    FILE_EXT="jar"
  else
    FILE_EXT="$PACKAGING"
  fi

  BASE_DIR=$(dirname $POM)
  TARGET="${POM::${#POM}-3}${FILE_EXT}"
  #TARGET=$(find $BASE_DIR -name "*.$FILE_EXT")

  echo "Pushing groupId $GROUP_ID artifactId $ARTIFACT_ID packaging $PACKAGING with label $CLASSIFICATION $DECORATOR $GRPS $COUNTRIES for $TARGET"

  # Push primary file and security label to gateway
#  curl -X POST -F "repository=$REPOSITORY" \
#    -F "groupId=$GROUP_ID" \
#    -F "artifactId=$ARTIFACT_ID" \
#    -F "version=$VERSION" \
#    -F "packaging=$PACKAGING" \
#    -F "classification=$CLASSIFICATION" \
#    -F "decorator=$DECORATOR" \
#    -F "groups=$GRPS" \
#    -F "countries=$COUNTRIES" \
#    http://$GATEWAY_HOST/gateway/
done