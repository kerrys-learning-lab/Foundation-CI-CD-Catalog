# ----------------------------------------------------------------------------
function should-skip() {
  local test_name=$1; shift

  for var_name in "${UNITTEST_REQUIRED_VARS[@]}" "$@"; do
    if [[ -z "${!var_name}" ]]; then
      bashunit::skip "Cannot test ${test_name} (missing value for ${var_name})"
      return 0
    fi
  done

  return 1
}
