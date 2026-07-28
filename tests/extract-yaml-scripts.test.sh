# ----------------------------------------------------------------------------
function test_good_example_files() {
  assert_file_exists /usr/local/bin/uut--tests-good-example--good-job-1
  assert_file_exists /usr/local/bin/uut--tests-good-example--good-job-2
  assert_file_exists /usr/local/bin/uut--tests-good-example--good-job-3
}


# ----------------------------------------------------------------------------
function test_good_example_job_1() {
  OUTPUT=$(/usr/local/bin/uut--tests-good-example--good-job-1)

  assert_contains "foo"   "${OUTPUT}"
  assert_contains "bar"   "${OUTPUT}"
  assert_contains "after" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
function test_good_example_job_2() {
  OUTPUT=$(/usr/local/bin/uut--tests-good-example--good-job-2)

  assert_contains "blam"    "${OUTPUT}"
  assert_contains "flobber" "${OUTPUT}"
}


# ----------------------------------------------------------------------------
function test_good_example_job_3() {
  OUTPUT=$(/usr/local/bin/uut--tests-good-example--good-job-3)

  assert_contains "good job 3"    "${OUTPUT}"
}


# ----------------------------------------------------------------------------
function test_empty_example() {
  OUTPUT=$(ls -alF /usr/local/bin/*empmty* 2>&1)

  assert_unsuccessful_code
  assert_contains "No such file or directory" "${OUTPUT}"
}
