$LOAD_PATH.unshift File.dirname(__FILE__)

# Add a require line for every file within framework/red_sky

require "red_sky/api_helpers/general"
require "red_sky/api_helpers/rest"

require "red_sky/ui_helpers/ui_general"

require "red_sky/watir/pages/rs_pages"
require "red_sky/watir/custom/all"
