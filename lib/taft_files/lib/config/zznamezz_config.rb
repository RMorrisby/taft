# Holds system configuration parameters

require_relative 'runtime_constants.rb'

class ZZnamezzConfig
    include RuntimeConstants
    
    CERTIFICATE_DIR = "certs"
    CERTIFICATE_POPUP_TIMEOUT = 15

    API_VERSION = "latest"

    SERVERS = {
        :test_1 => {:zznamezz_url => "https://"},
        :ref_1 => {:zznamezz_url => "https://"},
    }

    SERVER = SERVERS[$TEST_ENV]


    PASSED = "Passed"
    FAILED = "Failed"

    DISALLOWED_FIELD_NAMES = ["name"]

    ALL_USER_ROLES = ["all"]
end
