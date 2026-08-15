# ============================================================================


# ----------------------------------------------------------------------------
# Reset all inputs before each test so state never leaks between cases.
function set_up() {
  export CI_COMMIT_TAG=
  export CI_COMMIT_BRANCH=
  export CI_COMMIT_REF_NAME=
  export CI_COMMIT_REF_PROTECTED=
  export CI_DEFAULT_BRANCH=main
  export CI_PIPELINE_IID=42
  export CI_PIPELINE_SOURCE=push
  export DEFAULT_SEMVER_PREFIX=
  export TAGS_FOR_RELEASE_TRAIN=
  export PIPELINE_ARTIFACTS_DIR=$(bashunit::temp_dir)
  export SEMVER_STRICT=true
}


# ============================================================================
# Release tags  (vX.Y.Z, must be protected)
# ============================================================================

# ----------------------------------------------------------------------------
# @tag version
function test_protected_release_tag() {
  export CI_COMMIT_TAG=v1.2.3
  export CI_COMMIT_REF_NAME=v1.2.3
  export CI_COMMIT_REF_PROTECTED=true

  /usr/local/bin/uut--semver--pipeline-version

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "RELEASE_TRAIN=1.2"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "SEMANTIC_VERSION=1.2.3"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "SEMANTIC_VERSION_MAJOR=1"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "SEMANTIC_VERSION_MINOR=2"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "SEMANTIC_VERSION_PATCH=3"
}


# ----------------------------------------------------------------------------
# @tag version
function test_unprotected_release_tag_fails() {
  export CI_COMMIT_TAG=v1.2.3
  export CI_COMMIT_REF_NAME=v1.2.3
  export CI_COMMIT_REF_PROTECTED=false

  /usr/local/bin/uut--semver--pipeline-version

  assert_unsuccessful_code
}


# ----------------------------------------------------------------------------
# @tag version
function test_protected_nonconforming_tag_fails() {
  export CI_COMMIT_TAG=vNext
  export CI_COMMIT_REF_NAME=vNext
  export CI_COMMIT_REF_PROTECTED=true

  /usr/local/bin/uut--semver--pipeline-version

  assert_unsuccessful_code
}


# ----------------------------------------------------------------------------
# @tag version
function test_protected_unprefixed_tag_fails() {
  export CI_COMMIT_TAG=1.2.3
  export CI_COMMIT_REF_NAME=1.2.3
  export CI_COMMIT_REF_PROTECTED=true

  /usr/local/bin/uut--semver--pipeline-version

  assert_unsuccessful_code
}


# ----------------------------------------------------------------------------
# @tag version
function test_unprotected_nonconforming_tag_is_dev_build() {
  export CI_COMMIT_TAG=nightly
  export CI_COMMIT_REF_NAME=nightly
  export CI_COMMIT_REF_SLUG=nightly
  export CI_COMMIT_REF_PROTECTED=false

  local actual=$(/usr/local/bin/uut--semver--pipeline-version)

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "SEMANTIC_VERSION=0.0.0-nightly.42"
}


# ============================================================================
# Release branches  (release/X.Y, must be protected)
# ============================================================================

# ----------------------------------------------------------------------------
# @tag version
function test_unprotected_release_branch_fails() {
  export CI_COMMIT_BRANCH=release/1.2
  export CI_COMMIT_REF_NAME=release/1.2
  export CI_COMMIT_REF_PROTECTED=false

  /usr/local/bin/uut--semver--pipeline-version

  assert_unsuccessful_code
}


# ----------------------------------------------------------------------------
# @tag version
function test_release_branch_with_no_tags() {
  export CI_COMMIT_BRANCH=release/1.2
  export CI_COMMIT_REF_NAME=release/1.2
  export CI_COMMIT_REF_PROTECTED=true

  /usr/local/bin/uut--semver--pipeline-version

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "RELEASE_TRAIN=1.2"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "SEMANTIC_VERSION=1.2.0-rc.42"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "SEMANTIC_VERSION_MAJOR=1"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "SEMANTIC_VERSION_MINOR=2"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env  "SEMANTIC_VERSION_PATCH=0"
}


# ----------------------------------------------------------------------------
# @tag version
function test_release_branch_with_tags() {
  export CI_COMMIT_BRANCH=release/1.2
  export CI_COMMIT_REF_NAME=release/1.2
  export CI_COMMIT_REF_PROTECTED=true
  export TAGS_FOR_RELEASE_TRAIN="v1.2.0  v1.2.1  v1.2.2"

  /usr/local/bin/uut--semver--pipeline-version

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "RELEASE_TRAIN=1.2"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION=1.2.3-rc.42"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION_MAJOR=1"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION_MINOR=2"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION_PATCH=3"
}


# ----------------------------------------------------------------------------
# @tag version
function test_protected_nonrelease_branch_fails() {
  export CI_COMMIT_BRANCH=staging
  export CI_COMMIT_REF_NAME=staging
  export CI_COMMIT_REF_PROTECTED=true

  /usr/local/bin/uut--semver--pipeline-version

  assert_unsuccessful_code
}


# ============================================================================
# Default & developer branches  (dev builds)
# ============================================================================

# ----------------------------------------------------------------------------
# @tag version
function test_default_branch() {
  export CI_COMMIT_BRANCH=main
  export CI_COMMIT_REF_NAME=main
  export CI_COMMIT_REF_SLUG=main
  export CI_COMMIT_REF_PROTECTED=true

  /usr/local/bin/uut--semver--pipeline-version

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "RELEASE_TRAIN=main"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION=0.0.0-main.42"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION_MAJOR=0"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION_MINOR=0"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION_PATCH=0"
}


# ----------------------------------------------------------------------------
# @tag version
function test_developer_branch() {
  export CI_COMMIT_BRANCH=feat/18-developer-doing-work
  export CI_COMMIT_REF_NAME=feat/18-developer-doing-work
  export CI_COMMIT_REF_SLUG=feat-18-developer-doing-work
  export CI_COMMIT_REF_PROTECTED=false

  /usr/local/bin/uut--semver--pipeline-version

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION_MAJOR=0"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION_MINOR=0"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION_PATCH=0"
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION=0.0.0-feat-18-developer-doing-work.42"
}


# ============================================================================
# Merge request pipelines  (CI_COMMIT_BRANCH unset; TARGET drives the train)
# ============================================================================

# ----------------------------------------------------------------------------
# @tag version
function test_mr_into_release_branch_is_release_candidate() {
  export CI_COMMIT_REF_NAME=feat/42-some-fix
  export CI_COMMIT_REF_SLUG=feat-42-some-fix
  export CI_COMMIT_REF_PROTECTED=false
  export CI_PIPELINE_SOURCE=merge_request_event

  /usr/local/bin/uut--semver--pipeline-version

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "RELEASE_TRAIN="
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION=0.0.0-feat-42-some-fix.42"
}


# ----------------------------------------------------------------------------
# @tag version
function test_mr_from_release_branch() {
  export CI_COMMIT_REF_NAME=release/1.0
  export CI_COMMIT_REF_SLUG=release-1.0
  export CI_COMMIT_REF_PROTECTED=true
  export CI_PIPELINE_SOURCE=merge_request_event

  /usr/local/bin/uut--semver--pipeline-version

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "RELEASE_TRAIN="
  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION=0.0.0-release-1.0.42"
}


# ----------------------------------------------------------------------------
# @tag version
function test_mr_from_main_branch() {
  export CI_COMMIT_REF_NAME=main
  export CI_COMMIT_REF_SLUG=main
  export CI_COMMIT_REF_PROTECTED=true
  export CI_PIPELINE_SOURCE=merge_request_event

  /usr/local/bin/uut--semver--pipeline-version

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION=0.0.0-main.42"
}


# ============================================================================
# DEFAULT_SEMVER_PREFIX fallback
# ============================================================================

# ----------------------------------------------------------------------------
# @tag version
function test_custom_default_semver_prefix() {
  export CI_COMMIT_BRANCH=feat/x
  export CI_COMMIT_REF_NAME=feat/x
  export CI_COMMIT_REF_SLUG=feat-x
  export CI_COMMIT_REF_PROTECTED=false
  export DEFAULT_SEMVER_PREFIX=v9.9.9

  /usr/local/bin/uut--semver--pipeline-version

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION=9.9.9-feat-x.42"
}


# ----------------------------------------------------------------------------
# @tag version
function test_invalid_default_semver_prefix_falls_back() {
  export CI_COMMIT_BRANCH=feat/x
  export CI_COMMIT_REF_NAME=feat/x
  export CI_COMMIT_REF_SLUG=feat-x
  export CI_COMMIT_REF_PROTECTED=false
  export DEFAULT_SEMVER_PREFIX=not-a-semver

  /usr/local/bin/uut--semver--pipeline-version

  assert_file_contains ${PIPELINE_ARTIFACTS_DIR}/semver.env "SEMANTIC_VERSION=0.0.0-feat-x.42"
}
