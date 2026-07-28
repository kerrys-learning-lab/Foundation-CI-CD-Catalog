# ============================================================================
function set_up() {
  export GLAB_CHECK_UPDATE=false
  export GLAB_SEND_TELEMETRY=false
  export GLAB_SHOW_WHATS_NEW=false
  export RELEASE_NOTES_DIR=/foo/bar
  export RELEASE_README_FILEPATH=${RELEASE_NOTES_DIR}/README.md
  export CI_PIPELINE_IID=42
  export CI_PIPELINE_URL=http://www.example.com
}

function tear_down() {
  export GLAB_CHECK_UPDATE=
  export GLAB_SEND_TELEMETRY=
  export GLAB_SHOW_WHATS_NEW=
  export RELEASE_NOTES_DIR=
  export RELEASE_README_FILEPATH=
  export CI_PIPELINE_IID=
  export CI_PIPELINE_URL=
}


# ============================================================================


function test_release_notes_multiple_types() {
  export CI_COMMIT_TAG=foo-1.2.3
  export RELEASE_NOTES_DIR=$(bashunit::temp_dir)
  export RELEASE_README_FILEPATH=${RELEASE_NOTES_DIR}/RELEASE.md

  # --- Image type -----------------------------------------------------------
  mkdir ${RELEASE_NOTES_DIR}/image
  echo "image-1" > ${RELEASE_NOTES_DIR}/image/image-1.md
  echo "image-2" > ${RELEASE_NOTES_DIR}/image/image-2.md

  # --- Helm Chart type ------------------------------------------------------
  mkdir ${RELEASE_NOTES_DIR}/helm-chart
  echo "helm-chart-1" > ${RELEASE_NOTES_DIR}/helm-chart/helm-chart-1.md
  echo "helm-chart-2" > ${RELEASE_NOTES_DIR}/helm-chart/helm-chart-2.md

  OUTPUT=$(/usr/local/bin/uut--release--release 2>&1)
  cat -n ${RELEASE_README_FILEPATH}

  assert_file_exists    ${RELEASE_README_FILEPATH}
  assert_file_contains  ${RELEASE_README_FILEPATH}  "# Release foo-1.2.3"
  assert_file_contains  ${RELEASE_README_FILEPATH}  "Created by [Pipeline 42](http://www.example.com)"
  assert_file_contains  ${RELEASE_README_FILEPATH}  "## Image(s)"
  assert_file_contains  ${RELEASE_README_FILEPATH}  "image-1"
  assert_file_contains  ${RELEASE_README_FILEPATH}  "image-2"
  assert_file_contains  ${RELEASE_README_FILEPATH}  "## Helm Chart(s)"
  assert_file_contains  ${RELEASE_README_FILEPATH}  "helm-chart-1"
  assert_file_contains  ${RELEASE_README_FILEPATH}  "helm-chart-2"
}


function test_release_notes_type_dir_but_no_files() {
  export CI_COMMIT_TAG=foo-1.2.3
  export RELEASE_NOTES_DIR=$(bashunit::temp_dir)
  export RELEASE_README_FILEPATH=${RELEASE_NOTES_DIR}/RELEASE.md

  # --- Image type -----------------------------------------------------------
  mkdir ${RELEASE_NOTES_DIR}/image

  # --- Helm Chart type ------------------------------------------------------
  mkdir ${RELEASE_NOTES_DIR}/helm-chart

  OUTPUT=$(/usr/local/bin/uut--release--release 2>&1)

  assert_file_exists        ${RELEASE_README_FILEPATH}
  assert_file_contains      ${RELEASE_README_FILEPATH}   "# Release foo-1.2.3"
  assert_file_not_contains  ${RELEASE_README_FILEPATH}   "## Image(s)"
  assert_file_not_contains  ${RELEASE_README_FILEPATH}   "## Helm Chart(s)"
}


function test_no_release_notes_directory() {
  export CI_COMMIT_TAG=foo-1.2.3
  export RELEASE_README_FILEPATH=$(bashunit::temp_file)

  OUTPUT=$(/usr/local/bin/uut--release--release 2>&1)

  assert_equals "Release foo-1.2.3" "${OUTPUT}"
  assert_file_exists    ${RELEASE_README_FILEPATH}
  assert_file_contains  ${RELEASE_README_FILEPATH}  "# Release foo-1.2.3"
  assert_file_not_contains  ${RELEASE_README_FILEPATH}   "## Image(s)"
  assert_file_not_contains  ${RELEASE_README_FILEPATH}   "## Helm Chart(s)"
}
