
# This class holds parameters that may frequently change between test runs, e.g the test environment
module RuntimeConstants

    $TEST_ENV = :test_1

    CLOSE_BROWSER_AFTER_TEST = true # close the browser if the test passed?
    FORCE_CLOSE_BROWSER_AFTER_TEST = false # always close the browser?

    MAKE_ERROR_SCREENSHOTS = true
    ERROR_SCREENSHOT_LOCATION = "screenshots"

    WRITE_CI_REPORTS = false

    BROWSER = :chrome

    RESULTS_CSV = "results.csv"

end

