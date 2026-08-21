TESTS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
CHECK_REFS=${TESTS_DIR}/../scripts/check-refs

# Exit codes, mirroring scripts/check-refs
EXIT_OK=0
EXIT_DIVERGED=1
EXIT_USAGE=2


# ============================================================================
# NOTE: every fixture below deliberately contains references which disagree
#       with this project's own .release-manifest.yml, which is why that
#       manifest excludes tests/ from its scan.


# ----------------------------------------------------------------------------
function set_up() {
  FIXTURE=$(bashunit::temp_dir)

  cat > ${FIXTURE}/.release-manifest.yml <<'EOF'
version: 1
components:
  devsecops/cicd-catalog/foundation: $[[ component.reference ]]
  devsecops/cicd-catalog/image: release/0.2
images:
  devsecops/cicd-catalog/foundation: release-0.4
EOF
}


# ----------------------------------------------------------------------------
# Runs the check against ${FIXTURE}, capturing OUTPUT and EXIT_CODE
function run_check() {
  OUTPUT=$(${CHECK_REFS} --repo-root ${FIXTURE} "$@" 2>&1)
  EXIT_CODE=$?
}


# ----------------------------------------------------------------------------
function write_fixture_file() {
  local filename=$1

  cat > ${FIXTURE}/${filename}
}


# ============================================================================
# Component includes
# ============================================================================

# ----------------------------------------------------------------------------
# @tag refs
function test_matching_component_refs_pass() {
  bashunit::set_test_title "check-refs (matching component refs)"

  write_fixture_file .gitlab-ci.yml <<'EOF'
include:
  - component: $CI_SERVER_FQDN/devsecops/cicd-catalog/foundation/semver@$[[ component.reference ]]
  - component: $CI_SERVER_FQDN/devsecops/cicd-catalog/image/pipeline@release/0.2
EOF

  run_check

  assert_equals "${EXIT_OK}" "${EXIT_CODE}"
  assert_contains "Internally referenced components should not be declared" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
# @tag refs
function test_diverging_component_ref_is_reported_with_file_and_line() {
  bashunit::set_test_title "check-refs (diverging component ref)"

  write_fixture_file .gitlab-ci.yml <<'EOF'
include:
  - component: $CI_SERVER_FQDN/devsecops/cicd-catalog/foundation/semver@release/0.3
  - component: $CI_SERVER_FQDN/devsecops/cicd-catalog/foundation/release@$[[ component.reference ]]
EOF

  run_check

  assert_equals "${EXIT_DIVERGED}" "${EXIT_CODE}"
  assert_contains ".gitlab-ci.yml | 2" "${OUTPUT}"
  assert_contains ".gitlab-ci.yml | 3" "${OUTPUT}"
  assert_contains "Expected: \$[[ component.reference ]] / Actual: release/0.3" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
# @tag refs
function test_undeclared_component_project_is_reported() {
  bashunit::set_test_title "check-refs (undeclared component project)"

  write_fixture_file .gitlab-ci.yml <<'EOF'
include:
  - component: $CI_SERVER_FQDN/some/other/group/thing@main
EOF

  run_check

  assert_equals "${EXIT_DIVERGED}" "${EXIT_CODE}"
  assert_contains "Not declared in manifest" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
# @tag refs
function test_component_ref_without_a_version_is_reported() {
  bashunit::set_test_title "check-refs (component ref names no version)"

  write_fixture_file .gitlab-ci.yml <<'EOF'
include:
  - component: $CI_SERVER_FQDN/devsecops/cicd-catalog/foundation/semver
EOF

  run_check

  assert_equals "${EXIT_DIVERGED}" "${EXIT_CODE}"
  assert_contains "Invalid reference" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
# @tag refs
# 'component:' with no value is the spec:component: block of a component
# wrapper, not a reference
function test_component_key_without_a_value_is_not_a_reference() {
  bashunit::set_test_title "check-refs (spec:component: block)"

  write_fixture_file template.yml <<'EOF'
spec:
  component:
    - name
    - version
    - reference
EOF

  run_check

  assert_equals "${EXIT_OK}" "${EXIT_CODE}"
}


# ============================================================================
# Container images -- note the slug: release/0.4 vs release-0.4
# ============================================================================

# ----------------------------------------------------------------------------
# @tag refs
function test_matching_image_tags_pass() {
  bashunit::set_test_title "check-refs (matching image tags)"

  write_fixture_file defaults.yml <<'EOF'
variables:
  GLAB_JOB_IMAGE: $CI_REGISTRY/devsecops/cicd-catalog/foundation/glab:release-0.4
EOF

  run_check

  assert_equals "${EXIT_OK}" "${EXIT_CODE}"
}


# ----------------------------------------------------------------------------
# @tag refs
function test_diverging_image_tag_is_reported() {
  bashunit::set_test_title "check-refs (diverging image tag)"

  write_fixture_file defaults.yml <<'EOF'
variables:
  GLAB_JOB_IMAGE: $CI_REGISTRY/devsecops/cicd-catalog/foundation/glab:release-0.3
EOF

  run_check

  assert_equals "${EXIT_DIVERGED}" "${EXIT_CODE}"
  assert_contains "Expected: release-0.4 / Actual: release-0.3" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
# @tag refs
# An image tag is not a component ref: the slugged form is the only one which
# is valid in a tag
function test_component_style_ref_in_an_image_tag_is_reported() {
  bashunit::set_test_title "check-refs (component-style ref used as image tag)"

  write_fixture_file defaults.yml <<'EOF'
variables:
  GLAB_JOB_IMAGE: $CI_REGISTRY/devsecops/cicd-catalog/foundation/glab:release/0.4
EOF

  run_check

  assert_equals "${EXIT_DIVERGED}" "${EXIT_CODE}"
}


# ----------------------------------------------------------------------------
# @tag refs
# ...and the converse: the slugged form is not valid in a component ref
function test_slugged_ref_in_a_component_include_is_reported() {
  bashunit::set_test_title "check-refs (image-style tag used as component ref)"

  write_fixture_file .gitlab-ci.yml <<'EOF'
include:
  - component: $CI_SERVER_FQDN/devsecops/cicd-catalog/foundation/semver@release-0.4
EOF

  run_check

  assert_equals "${EXIT_DIVERGED}" "${EXIT_CODE}"
}


# ----------------------------------------------------------------------------
# @tag refs
# Ephemeral, per-pipeline tags carry no release version and must be left alone
function test_ephemeral_image_tags_are_ignored() {
  bashunit::set_test_title "check-refs (ephemeral image tags)"

  write_fixture_file .gitlab-ci.yml <<'EOF'
dogfood:
  image: $CI_REGISTRY_IMAGE/bashunit:build.$CI_PIPELINE_IID
base:
  image: docker.io/rockylinux/rockylinux:10.2-ubi
EOF

  run_check

  assert_equals "${EXIT_OK}" "${EXIT_CODE}"
}


# ----------------------------------------------------------------------------
# @tag refs
function test_undeclared_image_with_a_release_tag_is_reported() {
  bashunit::set_test_title "check-refs (undeclared image project)"

  write_fixture_file .gitlab-ci.yml <<'EOF'
build:
  image: $CI_REGISTRY/some/other/group/builder:release-0.3
EOF

  run_check

  assert_equals "${EXIT_DIVERGED}" "${EXIT_CODE}"
  assert_contains "some/other/group/builder:release-0.3 | Not declared in manifest" "${OUTPUT}"
}


# ============================================================================
# Opting out
# ============================================================================

# ----------------------------------------------------------------------------
# @tag refs
function test_ignored_paths_are_not_scanned() {
  bashunit::set_test_title "check-refs (manifest 'ignore:' globs)"

  cat >> ${FIXTURE}/.release-manifest.yml <<'EOF'
ignore:
  - docs/*
EOF

  mkdir -p ${FIXTURE}/docs
  write_fixture_file docs/example.yml <<'EOF'
include:
  - component: $CI_SERVER_FQDN/devsecops/cicd-catalog/foundation/semver@release/0.1
EOF

  run_check

  assert_equals "${EXIT_OK}" "${EXIT_CODE}"
}


# ----------------------------------------------------------------------------
# @tag refs
function test_ignore_marker_opts_a_single_line_out() {
  bashunit::set_test_title "check-refs ('check-refs: ignore' marker)"

  write_fixture_file README.md <<'EOF'
For example:
  - component: $CI_SERVER_FQDN/devsecops/cicd-catalog/foundation/semver@release/0.1  (check-refs: ignore)
EOF

  run_check

  assert_equals "${EXIT_OK}" "${EXIT_CODE}"
}


# ============================================================================
# The manifest itself
# ============================================================================

# ----------------------------------------------------------------------------
# @tag refs
function test_missing_manifest_is_a_usage_error() {
  bashunit::set_test_title "check-refs (missing manifest)"

  rm -f ${FIXTURE}/.release-manifest.yml

  run_check

  assert_equals "${EXIT_USAGE}" "${EXIT_CODE}"
  assert_contains "manifest not found" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
# @tag refs
function test_unsupported_manifest_version_is_refused() {
  bashunit::set_test_title "check-refs (unsupported manifest version)"

  cat > ${FIXTURE}/.release-manifest.yml <<'EOF'
version: 99
components:
  devsecops/cicd-catalog/foundation: release/0.4
EOF

  run_check

  assert_equals "${EXIT_USAGE}" "${EXIT_CODE}"
  assert_contains "unsupported manifest version" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
# @tag refs
# The manifest declares the intent; it must never be checked against itself
function test_manifest_is_not_scanned_as_a_reference_site() {
  bashunit::set_test_title "check-refs (manifest excluded from the scan)"

  run_check

  assert_equals "${EXIT_OK}" "${EXIT_CODE}"
  assert_not_contains ".release-manifest.yml:" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
# @tag refs
function test_declaration_which_governs_nothing_is_warned_about() {
  bashunit::set_test_title "check-refs (stale manifest declaration)"

  write_fixture_file .gitlab-ci.yml <<'EOF'
include:
  - component: $CI_SERVER_FQDN/devsecops/cicd-catalog/foundation/semver@$[[ component.reference ]]
EOF

  run_check

  assert_equals "${EXIT_OK}" "${EXIT_CODE}"
  assert_contains "Declared but never referenced" "${OUTPUT}"
}


# ============================================================================
# Flag only -- never rewrite
# ============================================================================

# ----------------------------------------------------------------------------
# @tag refs
function test_diverging_files_are_never_rewritten() {
  bashunit::set_test_title "check-refs (flags, never rewrites)"

  write_fixture_file .gitlab-ci.yml <<'EOF'
include:
  - component: $CI_SERVER_FQDN/devsecops/cicd-catalog/foundation/semver@release/0.1
EOF

  BEFORE=$(cat ${FIXTURE}/.gitlab-ci.yml)

  run_check

  assert_equals "${EXIT_DIVERGED}" "${EXIT_CODE}"
  assert_same "${BEFORE}" "$(cat ${FIXTURE}/.gitlab-ci.yml)"
}


# ============================================================================
# Command line
# ============================================================================


# ----------------------------------------------------------------------------
# @tag refs
function test_unknown_argument_is_a_usage_error() {
  bashunit::set_test_title "check-refs (unknown argument)"

  run_check --wat

  assert_equals "${EXIT_USAGE}" "${EXIT_CODE}"
  assert_contains "unknown argument" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
# @tag refs
function test_help_is_available_and_successful() {
  bashunit::set_test_title "check-refs (--help)"

  run_check --help

  assert_equals "${EXIT_OK}" "${EXIT_CODE}"
  assert_contains "--verify-upstream" "${OUTPUT}"
}
