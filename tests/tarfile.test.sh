TESTS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
. ${TESTS_DIR}/.bashunit-helpers/glab-assertions.sh


# ============================================================================
function set_up() {
  export CI_PROJECT_NAME=test-project
  export SEMANTIC_VERSION=1.2.3
  export TARFILE_NAME=
  export TARFILE_VERSION=SEMANTIC_VERSION
  export TARFILE_EXTENSION=tar.gz
  export TARFILE_TRANSFORM_PREFIX=default
  export TARFILE_MEMBERS=.

  export TARFILE_CONTEXT=$(bashunit::temp_dir)
  export PIPELINE_ARTIFACTS_DIR=$(bashunit::temp_dir)
  mkdir ${TARFILE_CONTEXT}/foo
  mkdir ${TARFILE_CONTEXT}/bar
  touch ${TARFILE_CONTEXT}/foo/foo.txt
  touch ${TARFILE_CONTEXT}/bar/bar.txt
}


# ============================================================================


# ----------------------------------------------------------------------------
function test_cicd_tarfile_build_default() {
  bashunit::set_test_title "CI/CD tarfile-build (default)"
  export CI_PROJECT_NAME=foo
  export SEMANTIC_VERSION_SLUG=1.2.3

  . /usr/local/bin/uut--tarfile--tarfile-base
  export TARFILE_NAME
  export TARFILE_VERSION
  export TARFILE_FULL_NAME

  /usr/local/bin/uut--tarfile--tarfile-build

  assert_file_exists "${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz"

  TARFILE_CONTENTS=$(tar tzf ${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz)

  assert_matches "foo-1.2.3/foo/foo.txt" "${TARFILE_CONTENTS}"
  assert_matches "foo-1.2.3/bar/bar.txt" "${TARFILE_CONTENTS}"
}


# ----------------------------------------------------------------------------
function test_cicd_tarfile_build_custom_name() {
  bashunit::set_test_title "CI/CD tarfile-build (custom name)"
  export CI_PROJECT_NAME=foo
  export SEMANTIC_VERSION_SLUG=1.2.3
  export TARFILE_NAME=blah

  . /usr/local/bin/uut--tarfile--tarfile-base
  export TARFILE_NAME
  export TARFILE_VERSION
  export TARFILE_FULL_NAME

  /usr/local/bin/uut--tarfile--tarfile-build

  assert_file_exists "${PIPELINE_ARTIFACTS_DIR}/blah-1.2.3.tar.gz"

  TARFILE_CONTENTS=$(tar tzf ${PIPELINE_ARTIFACTS_DIR}/blah-1.2.3.tar.gz)

  assert_matches "blah-1.2.3/foo/foo.txt" "${TARFILE_CONTENTS}"
  assert_matches "blah-1.2.3/bar/bar.txt" "${TARFILE_CONTENTS}"
}


# ----------------------------------------------------------------------------
function test_cicd_tarfile_build_custom_version() {
  bashunit::set_test_title "CI/CD tarfile-build (custom version)"
  export CI_PROJECT_NAME=foo
  export TEST_IDENTIFIER_TO_BE_EXPANDED=a.b.c
  export TARFILE_VERSION=TEST_IDENTIFIER_TO_BE_EXPANDED

  . /usr/local/bin/uut--tarfile--tarfile-base
  export TARFILE_NAME
  export TARFILE_VERSION
  export TARFILE_FULL_NAME

  /usr/local/bin/uut--tarfile--tarfile-build

  assert_file_exists "${PIPELINE_ARTIFACTS_DIR}/foo-a.b.c.tar.gz"

  TARFILE_CONTENTS=$(tar tzf ${PIPELINE_ARTIFACTS_DIR}/foo-a.b.c.tar.gz)

  assert_matches "foo-a.b.c/foo/foo.txt" "${TARFILE_CONTENTS}"
  assert_matches "foo-a.b.c/bar/bar.txt" "${TARFILE_CONTENTS}"
}


# ----------------------------------------------------------------------------
function test_cicd_tarfile_build_content() {
  bashunit::set_test_title "CI/CD tarfile-build (custom content)"
  export CI_PROJECT_NAME=foo
  export SEMANTIC_VERSION_SLUG=1.2.3
  export TARFILE_MEMBERS=foo

  . /usr/local/bin/uut--tarfile--tarfile-base
  export TARFILE_NAME
  export TARFILE_VERSION
  export TARFILE_FULL_NAME

  /usr/local/bin/uut--tarfile--tarfile-build

  assert_file_exists "${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz"

  TARFILE_CONTENTS=$(tar tzf ${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz)

  assert_matches      "foo-1.2.3/foo/foo.txt"   "${TARFILE_CONTENTS}"
  assert_not_contains "bar"                     "${TARFILE_CONTENTS}"
}


# ----------------------------------------------------------------------------
function test_cicd_tarfile_build_ignorefile() {
  bashunit::set_test_title "CI/CD tarfile-build (ignorefile)"
  export CI_PROJECT_NAME=foo
  export SEMANTIC_VERSION_SLUG=1.2.3
  export TARFILE_IGNOREFILE=$(bashunit::temp_file)

  echo "./bar" >> ${TARFILE_IGNOREFILE}

  . /usr/local/bin/uut--tarfile--tarfile-base
  export TARFILE_NAME
  export TARFILE_VERSION
  export TARFILE_FULL_NAME

  /usr/local/bin/uut--tarfile--tarfile-build

  assert_file_exists "${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz"

  TARFILE_CONTENTS=$(tar tzf ${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz)

  assert_matches      "foo-1.2.3/foo/foo.txt"   "${TARFILE_CONTENTS}"
  assert_not_contains "bar"                     "${TARFILE_CONTENTS}"
}


# ----------------------------------------------------------------------------
function test_cicd_tarfile_build_no_transform() {
  bashunit::set_test_title "CI/CD tarfile-build (no transform)"
  export CI_PROJECT_NAME=foo
  export SEMANTIC_VERSION_SLUG=1.2.3
  export TARFILE_TRANSFORM_PREFIX=none

  . /usr/local/bin/uut--tarfile--tarfile-base
  export TARFILE_NAME
  export TARFILE_VERSION
  export TARFILE_FULL_NAME

  /usr/local/bin/uut--tarfile--tarfile-build

  assert_file_exists "${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz"

  TARFILE_CONTENTS=$(tar tzf ${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz)

  assert_matches  "foo/foo.txt"   "${TARFILE_CONTENTS}"
  assert_matches  "bar/bar.txt"   "${TARFILE_CONTENTS}"
}


# ----------------------------------------------------------------------------
function test_cicd_tarfile_build_custom_transform() {
  bashunit::set_test_title "CI/CD tarfile-build (custom transform)"
  export CI_PROJECT_NAME=foo
  export SEMANTIC_VERSION_SLUG=1.2.3
  export TARFILE_TRANSFORM_PREFIX=custom-transform

  . /usr/local/bin/uut--tarfile--tarfile-base
  export TARFILE_NAME
  export TARFILE_VERSION
  export TARFILE_FULL_NAME

  /usr/local/bin/uut--tarfile--tarfile-build

  assert_file_exists "${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz"

  TARFILE_CONTENTS=$(tar tzf ${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz)

  assert_matches  "custom-transform/foo/foo.txt"   "${TARFILE_CONTENTS}"
  assert_matches  "custom-transform/bar/bar.txt"   "${TARFILE_CONTENTS}"
}


# ----------------------------------------------------------------------------
function test_cicd_tarfile_build_output_file_in_context() {
  bashunit::set_test_title "CI/CD tarfile-build (output file is in context)"
  export CI_PROJECT_NAME=foo
  export SEMANTIC_VERSION_SLUG=1.2.3
  export PIPELINE_ARTIFACTS_DIR=${TARFILE_CONTEXT}

  . /usr/local/bin/uut--tarfile--tarfile-base
  export TARFILE_NAME
  export TARFILE_VERSION
  export TARFILE_FULL_NAME

  /usr/local/bin/uut--tarfile--tarfile-build

  assert_file_exists "${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz"

  TARFILE_CONTENTS=$(tar tzf ${PIPELINE_ARTIFACTS_DIR}/foo-1.2.3.tar.gz)

  echo ${TARFILE_CONTENTS}

  assert_matches      "foo-1.2.3/foo/foo.txt"   "${TARFILE_CONTENTS}"
  assert_matches      "foo-1.2.3/bar/bar.txt"   "${TARFILE_CONTENTS}"
  assert_not_contains "tgz"                     "${TARFILE_CONTENTS}"
}



# ============================================================================


# ----------------------------------------------------------------------------
function test_cicd_tarfile_publish_default() {
  bashunit::set_test_title "CI/CD tarfile-publish (default)"

  export TARFILE_PREFIX=zzz-unittest
  export TARFILE_NAME=${TARFILE_PREFIX}-ephemeral-artifacts-$(bashunit::random_str)
  export TARFILE_VERSION=1.2.3
  export TARFILE_FULL_NAME=${TARFILE_NAME}-${TARFILE_VERSION}.${TARFILE_EXTENSION}

  /usr/local/bin/uut--tarfile--tarfile-build

  /usr/local/bin/uut--tarfile--tarfile-publish

  export TAR_PACKAGE_ARTIFACT_EXTRACT_DIR=./$(bashunit::random_str)
  export TAR_PACKAGE_PUBLISH_REPO=https://gitlab.westsidestreet.net/devsecops/cicd-catalog/foundation

  mkdir ${TAR_PACKAGE_ARTIFACT_EXTRACT_DIR}

  assert_glab_generic_package_download  ${TARFILE_NAME}  \
                                        ${TARFILE_VERSION}  \
                                        ${TAR_PACKAGE_ARTIFACT_EXTRACT_DIR}  \
                                        ${TARFILE_FULL_NAME}

  PACKAGE_LIST=$(glab packages list --package-type generic)

  while IFS= read -r package; do
    id=$(jq -r '.id' <<< "${package}")
    name=$(jq -r '.name' <<< "${package}")

    if [[ ${name} == ${TARFILE_PREFIX}* ]]; then
      bashunit::log "glab" "Removing generic package: ${name}"
      glab packages delete --yes ${id}
    fi
  done < <(jq -c '.[]' <<< "${PACKAGE_LIST}")
}


# ----------------------------------------------------------------------------
function test_cicd_tarfile_publish_file_not_exists() {
  bashunit::set_test_title "CI/CD tarfile-publish (file doesn't exist)"

  /usr/local/bin/uut--tarfile--tarfile-publish

  assert_unsuccessful_code
}
