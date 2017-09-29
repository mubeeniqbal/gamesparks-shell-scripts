#!/bin/bash
#
# REST API documentation:
# https://docs.gamesparks.com/api-documentation/nosql-rest-api.html
#
# This script has a dependency on jq: https://stedolan.github.io/jq/

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

  command="echo '${response}' | jq '.${STAGE}Nosql'"
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

  command="echo '${response}' | jq '.\"X-GS-JWT\"'"
  JWT="$(eval "${command}")"
  readonly JWT
  echo -e "\n${YELLOW}JSON Web Token: ${JWT}${RC}"
}

discover_endpoints
echo -e "\n--------------------\n"
auth_nosql
