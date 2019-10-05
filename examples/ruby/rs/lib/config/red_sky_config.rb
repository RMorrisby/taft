# Holds system configuration parameters

require_relative 'runtime_constants.rb'

class RedSkyConfig
    include RuntimeConstants
    
    CERTIFICATE_DIR = "certs"
    CERTIFICATE_POPUP_TIMEOUT = 15

    API_VERSION = "latest"

    SERVERS = {
        :test_1 => {:red_sky_url => "https://www.google.co.uk"},
        :ref_1 => {:red_sky_url => "https://"},
    }

    SERVER = SERVERS[$TEST_ENV]


    PASSED = "Passed"
    FAILED = "Failed"

    DISALLOWED_FIELD_NAMES = ["name"]

    ALL_USER_ROLES = ["all"]
end
