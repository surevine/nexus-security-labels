                                                                                      99,1          Bot
#!/bin/bash

#
# Monitors a directory for changes since last check.
#
# Bugs:
#   * Manually updated files with same security labels aren't detected
#   * Doesn't pick up deletions as the files don't exist
#

set -e

GATEWAY_HOST="127.0.0.1"
REPO_PATH="$1"
MONITOR_F="/tmp/.nm-$(echo -n "$REPO_PATH" | md5sum | awk '{print $1}')"

function find_files {
  if [[ ! -f $MONITOR_F ]]; then
    echo "Warning. First use returns all files."
    FILES=($(find $REPO_PATH/* -type f -name "*-securitylabel.xml" | grep -v "\.nexus/"))
  else
    FILES=($(find $REPO_PATH/* -type f -cnewer $MONITOR_F -name "*-securitylabel.xml" | grep -v "\.nexus/"))
  fi

  touch $MONITOR_F
}

function get_xml {
  local result="$(./parsexml.sh $1 $2 $3 | tr '\n' ',' | sed 's/,$//g')"
  echo $result
}

function get_mvn {
  local result="$(./parsexml.py $1 $2)"
  echo $result
}

find_files

for LABEL in ${FILES[@]}; do
  POM=$(echo $LABEL | sed 's/-securitylabel\.xml$/.pom/') # pom.xml

  # Find primary file
  PACKAGING=$(get_mvn "$POM" "packaging")
  ARTIFACT_ID=$(get_mvn "$POM" "artifactId")
  GROUP_ID=$(get_mvn "$POM" "groupId")
  VERSION=$(get_mvn "$POM" "version")
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
  POM_FNAME=$(basename $POM)
  POM_NAME="${POM_FNAME::${#POM_FNAME}-4}"
  TARGET="${POM_NAME}.${FILE_EXT}"
  TMP_DIR="/tmp/gateway/$POM_NAME"

  mkdir -p "${TMP_DIR}"
  cd "${TMP_DIR}"

  # Write out our metadata file
  # Should probably be using arrays rather than CSVs
  echo "{
  \"repository\": \"$REPOSITORY\",
  \"groupId\": \"$GROUP_ID\",
  \"artifactId\": \"$ARTIFACT_ID\",
  \"version\": \"$VERSION\",
  \"packaging\": \"$PACKAGING\",
  \"classification\": \"$CLASSIFICATION\",
  \"decorator\": \"$DECORATOR\",
  \"groups\": \"$GRPS\",
  \"countries\": \"$COUNTRIES\",
  \"source_type\": \"NEXUS\"
}" > ".metadata.json"

  cat .metadata.json

  # Copy the content next to the metadata
  cp "$BASE_DIR/$TARGET" "$(basename $TARGET)"

  # Build our export package to send to gateway
  tar czf "$POM_NAME.tgz" "$(basename $TARGET)" ".metadata.json"

  # POST export package to gateway
  curl -X POST \
    -F "filename=$POM_NAME.tgz" \
    -F "file=@$POM_NAME.tgz" \
    -F "repository=$REPOSITORY" \
    -F "groupId=$GROUP_ID" \
    -F "artifactId=$ARTIFACT_ID" \
    -F "version=$VERSION" \
    -F "packaging=$PACKAGING" \
    -F "classification=$CLASSIFICATION" \
    -F "decorator=$DECORATOR" \
    -F "groups=$GRPS" \
    -F "countries=$COUNTRIES" \
    -F "source_type=NEXUS" \
    http://$GATEWAY_HOST/gateway/api/export/

  cd -
  rm -rf "${TMP_DIR}"
done