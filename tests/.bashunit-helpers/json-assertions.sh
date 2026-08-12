

# ----------------------------------------------------------------------------
function assert_json_name_value() {
  local required_args=(name file)

  local name=$1
  local value=$2
  local file=$3

  for required in ${required_args[@]}; do
    if [[ -z "${!required}" ]]; then
      bashunit::assertion_failed "Call to assert_json_name_value is invalid!  Missing required argument: ${required}"
    fi
  done

  if [[ ! -f "${file}" ]]; then
    bashunit::assertion_failed "File does not exist: ${file}"
  fi

  local jq_cli_args=()
  jq_cli_args+=(--slurp)
  jq_cli_args+=(--arg name "${name}")
  jq_cli_args+=(--arg value "${value}")
  jq_cli_args+=('any(.[] ; .name == $name and .value == $value)')

  jq_result=$(jq "${jq_cli_args[@]}" ${file})
  if [[ "${jq_result}" == "true" ]]; then
    bashunit::assertion_passed
  else
    bashunit::assertion_failed "Name/value pair not found in ${file}: ${name}/${value}"
  fi
}
