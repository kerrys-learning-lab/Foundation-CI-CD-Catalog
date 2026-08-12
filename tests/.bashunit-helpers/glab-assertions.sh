

# ----------------------------------------------------------------------------
function assert_glab_generic_package_download() {
  local required_args=(name version output_dir)

  local name=$1
  local version=$2
  local output_dir=$3
  local filename=$4

  for required in ${required_args[@]}; do
    if [[ -z "${!required}" ]]; then
      bashunit::assertion_failed "Call to assert_glab_generic_package_download is invalid!  Missing required argument: ${required}"
    fi
  done

  if [[ -z "${filename}" ]]; then
    filename=${name}-${version}.tgz
    filename=${filename,,}
  fi

  glab packages download  --name      ${name}  \
                          --version   ${version}  \
                          --path      ${output_dir}  \
                          --filename  ${filename}

  if [[ ! -f ${output_dir}/${filename} ]]; then
    bashunit::assertion_failed "File: ${filename}" "Unable to download generic package"
  else
    bashunit::assertion_passed
    tar --directory ${output_dir}  \
        --extract  \
        --auto-compress  \
        --file ${output_dir}/${filename} || true
  fi

}
