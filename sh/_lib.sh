scriptdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
basedir=$(echo "${scriptdir}" | grep -Po ".*(?=\/)")
confdir="${basedir}/configs"

export PATH="${PATH}:${scriptdir}"

decode="false"
dryrun="false"
verbose="false"
conf_arg="conf"
for val in "$@"; do
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

gk() {
  stoml "${conf}" "${1}" | envsubst
}

header() {
  echo -e "\n\033[0;93m${@}\033[0m"
}

conf="$(
  find "${confdir}" -mindepth 1 -maxdepth 1 -regex "\/.*${conf_arg}.*\.toml$" |
    sort | head -n 1
)"

if [[ ! -f "${conf}" || -z "${conf}" ]]; then
  echo -e "\n[error] config file not found, failed lookup was \"${conf_arg}\"\n"
  exit 1
fi

if [[ "${verbose}" == "true" ]]; then
  header "read config: ${conf}"
fi

export KEYCLOAK_REALM="$(gk keycloak.realm)"
export KEYCLOAK_HOST="$(gk keycloak.host)"
export KEYCLOAK_OIDC_URL="$(gk keycloak.oidc_url)"
export CLIENT_ID="$(gk client.id)"
export CLIENT_SECRET="$(gk client.secret)"
export USER_NAME="$(gk user.name)"
export USER_PASS="$(gk user.pass)"
export USER_CLIENT_ID="$(gk user.client_id)"
