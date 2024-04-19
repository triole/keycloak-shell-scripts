scriptdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
basedir=$(echo "${scriptdir}" | grep -Po ".*(?=\/)")
confdir="${basedir}/conf"

export PATH="${PATH}:${scriptdir}"

decode="false"
dryrun="false"
verbose="false"
conf_arg=""
for val in "${@}"; do
  if [[ "${val}" =~ ^([0-9a-zA-Z]+)$ ]]; then
    conf_arg="${val}"
  fi
  if [[ "${val}" =~ ^-+(d|decode)$ ]]; then
    decode="true"
  fi
  if [[ "${val}" =~ ^-+(n|dryrun)$ ]]; then
    dryrun="true"
  fi
  if [[ "${val}" =~ ^-+(v|verbose)$ ]]; then
    verbose="true"
  fi
  if [[ "${val}" =~ ^-+(h|help)$ ]]; then
    echo -e "\nargs"
    echo "  -d/--decode   decode token before displaying"
    echo "  -v/--verbose  verbose mode"
    echo ""
    exit 0
  fi
done

display() {
  arg1="${1}"
  arg2="${2}"
  if [[ "${verbose}" == "true" ]]; then
    header "display token"
  fi
  if [[ "${decode}" == "true" ]]; then
    for el in $(echo "${arg1}" | sed "s|\.| |g"); do
      echo -n "${el}" | base64 -di | jq
    done
  else
    if [[ "${arg2}" == "-f" ]]; then
      echo "${arg1}" | jq
    else
      echo "${arg1}"
    fi
  fi
  echo ""
}

conf="$(
  find "${confdir}" -mindepth 1 -maxdepth 1 |
    grep -Eo "${confdir}\/.*${conf_arg}.*\.toml$" |
    sort | head -n 1
)"

if [[ ! -f "${conf}" ]]; then
  echo -e "\n[error] config file not found, failed lookup was \"${conf_arg}\"\n"
  exit 1
fi

gk() {
  stoml "${conf}" "${1}" | envsubst
}

header() {
  echo -e "\n\033[0;93m${@}\033[0m"
}

if [[ -z "${conf_arg}" ]]; then
  echo -e "\n[error] config arg required to be able to look up config file\n"
  exit 1
fi

export IDP_REALM="$(gk idp.realm)"
export IDP_HOST="$(gk idp.host)"
export IDP_WELL_KNOWN="$(gk idp.well_known)"
export CLIENT_ID="$(gk client.id)"
export CLIENT_SECRET="$(gk client.secret)"
export USER_NAME="$(gk user.name)"
export USER_PASS="$(gk user.pass)"
export USER_CLIENT_ID="$(gk user.client_id)"

api_info() {
  curl -sL \-X GET ${IDP_WELL_KNOWN} | jq
}

discover_endpoint() {
  api_info | jq -r "${1}"
}

export ENDPOINT_USERINFO="$(discover_endpoint ".userinfo_endpoint")"
export ENDPOINT_TOKEN="$(discover_endpoint ".token_endpoint")"

if [[ "${verbose}" == "true" ]]; then
  header "read config ${conf}"
  {
    env | grep -E "^IDP_"
    env | grep -E "^CLIENT_"
    env | grep -E "^USER_"
    env | grep -E "^ENDPOINT_"
  } | sort
fi
