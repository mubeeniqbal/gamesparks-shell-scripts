#!/bin/bash
#
# REST API documentation:
# https://docs.gamesparks.com/api-documentation/nosql-rest-api.html
#
# This script has a dependency on jq: https://stedolan.github.io/jq/
# Make sure jq is installed on your system and is present in PATH.

### Colors ###

readonly RC='\033[0m' # Reset color

readonly BLACK='\033[0;30m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'

readonly BRIGHT_BLACK='\033[1;30m'
readonly BRIGHT_RED='\033[1;31m'
readonly BRIGHT_GREEN='\033[1;32m'
readonly BRIGHT_YELLOW='\033[1;33m'
readonly BRIGHT_BLUE='\033[1;34m'
readonly BRIGHT_MAGENTA='\033[1;35m'
readonly BRIGHT_CYAN='\033[1;36m'
readonly BRIGHT_WHITE='\033[1;37m'

### End Colors ###

readonly AUTH_URL='https://auth.gamesparks.net'
readonly CONFIG_URL='https://config2.gamesparks.net'

# Fill in these fields before using this script.
readonly USERNAME=''
readonly PASSWORD=''
readonly API_KEY=''
readonly STAGE=''

declare -a SYSTEM_COLLECTIONS
declare -a RUNTIME_COLLECTIONS

STAGE_BASE_URL=''
JWT=''

discover_endpoints() {
  echo -e "${MAGENTA}Discovering endpoints...${RC}\n"

  local command="curl --silent --user ${USERNAME}:${PASSWORD} -X GET --header 'Accept: application/json' ${CONFIG_URL}/restv2/game/${API_KEY}/endpoints"
  echo -e "> ${CYAN}${command}${RC}\n"

  local response
  response="$(eval "${command}")"

  # Pretty print JSON reponse
  eval "echo '${response}' | jq '.'"

  # Use jq --raw-output to remove get string without quotes.
  command="echo '${response}' | jq --raw-output '.${STAGE}Nosql'"
  STAGE_BASE_URL="$(eval "${command}")"
  readonly STAGE_BASE_URL
  echo -e "\n${YELLOW}Stage Base URL: ${STAGE_BASE_URL}${RC}"
}

auth_nosql() {
  echo -e "${MAGENTA}Authenticating user to access NoSQL database...${RC}\n"

  local filter='nosql'
  local command="curl --silent --user ${USERNAME}:${PASSWORD} -X GET --header 'Accept: application/json' ${AUTH_URL}/restv2/auth/game/${API_KEY}/jwt/${filter}"
  echo -e "> ${CYAN}${command}${RC}\n"

  local response
  response="$(eval "${command}")"

  # Pretty print JSON reponse
  eval "echo '${response}' | jq '.'"

  # Use jq --raw-output to remove get string without quotes.
  command="echo '${response}' | jq --raw-output '.\"X-GS-JWT\"'"
  JWT="$(eval "${command}")"
  readonly JWT
  echo -e "\n${YELLOW}JSON Web Token: ${JWT}${RC}"
}

list_collections() {
  echo -e "${MAGENTA}Listing NoSQL database collections...${RC}\n"

  local filter='nosql'
  local command="curl --silent -X GET --header 'Accept: application/json' --header 'X-GS-JWT: ${JWT}' ${STAGE_BASE_URL}/restv2/game/${API_KEY}/mongo/collections"
  echo -e "> ${CYAN}${command}${RC}\n"

  local response
  response="$(eval "${command}")"

  # Pretty print JSON reponse
  eval "echo '${response}' | jq '.'"

  # System collections

  # Use jq --raw-output to remove get string without quotes.
  # We base64 encode to get rid of spaces and newlines. Later on we will
  # base64 decode all the values.
  command="echo '${response}' | jq --raw-output '.[] | select(.optionGroup == \"System\") | .name | @base64'"

  local collection
  unset SYSTEM_COLLECTIONS

  for collection_base64 in $(eval "${command}")
  do
    # We have to output this way to append newline character at the end.
    collection="$(echo "$(echo "${collection_base64}" | base64 --decode)")"
    SYSTEM_COLLECTIONS+=("${collection}")
  done

  echo -e "\n${YELLOW}System Collections: ${SYSTEM_COLLECTIONS[*]}${RC}"

  # Runtime collections

  # Use jq --raw-output to remove get string without quotes.
  # We base64 encode to get rid of spaces and newlines. Later on we will
  # base64 decode all the values.
  command="echo '${response}' | jq --raw-output '.[] | select(.optionGroup == \"Runtime\") | .name | @base64'"

  unset RUNTIME_COLLECTIONS

  for collection_base64 in $(eval "${command}")
  do
    # We have to output this way to append newline character at the end.
    collection="$(echo "$(echo "${collection_base64}" | base64 --decode)")"
    RUNTIME_COLLECTIONS+=("${collection}")
  done

  echo -e "\n${YELLOW}Runtime Collections: ${RUNTIME_COLLECTIONS[*]}${RC}"

  # TODO(mubeeniqbal): Add Meta, Leaderboards and Running Totals collections.
}

remove_system_collection_documents() {
  echo -e "${MAGENTA}Removing documents from system collections...${RC}"

  for collection in "${SYSTEM_COLLECTIONS[@]}"
  do
    echo -e "\n${YELLOW}Removing all documents from collection '${collection}'...${RC}\n"

    local command="curl --silent -X POST --header 'Content-Type: application/json;charset=UTF-8' --header 'Accept: application/json' --header 'X-GS-JWT: ${JWT}' -d '{ \"query\": {} }' ${STAGE_BASE_URL}/restv2/game/${API_KEY}/mongo/collection/${collection}/remove"
    echo -e "> ${CYAN}${command}${RC}\n"

    local response
    response="$(eval "${command}")"

    # Pretty print JSON reponse
    eval "echo '${response}' | jq '.'"
  done
}

delete_runtime_collections() {
  echo -e "${MAGENTA}Deleting runtime collections...${RC}"

  for collection in "${RUNTIME_COLLECTIONS[@]}"
  do
    echo -e "\n${YELLOW}Deleting collection '${collection}'...${RC}\n"

    local command="curl --silent -X DELETE --header 'Accept: application/json' --header 'X-GS-JWT: ${JWT}' ${STAGE_BASE_URL}/restv2/game/${API_KEY}/mongo/collection/${collection}"
    echo -e "> ${CYAN}${command}${RC}\n"

    local response
    response="$(eval "${command}")"

    # Pretty print JSON reponse
    eval "echo '${response}' | jq '.'"
  done
}

nuke_nosql() {
  remove_documents
  echo -e '\n--------------------\n'
  delete_collections
}

discover_endpoints
echo -e '\n--------------------\n'
auth_nosql
echo -e '\n--------------------\n'
list_collections
echo -e '\n--------------------\n'
nuke_nosql
