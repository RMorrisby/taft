$LOAD_PATH.unshift("#{File.expand_path(File.dirname(__FILE__))}/../../lib")

require "red_sky_test_case"

class TC_R001_01_GOOGLE_SEARCH < Test::Unit::TestCase
    include RedSkyTestCase
    
    def setup
        # specify setup parameters
        @certificate = :regular # this is the default user for this test
        @initialBrowser = :none # if you want this test to navigate to your webapp automatically as part of setup, change this value to the value referring to your webapp

        super # must call super so that the common setup method in RedSkyTestCase is called
    end

    def test_r001_01_google_search

        ############################################################################################
        # PURPOSE :
        #   Verify that Google searches can be made
        # 
        # PRECONDITIONS :
        #   None
        ############################################################################################

        @help.ui_helper_test

        # Step 1 :
        #   Open the Google Search page

        google_login

        # Expected Result :
        #   The RED SKY homepage is displayed

        assert(googleSearch.displayed?, "The Google search page is not displayed")

        
        # Step 3 :
        #   Enter in a search term and click the Search button.

        term = "Ruby"

        puts "Will now search for '#{term}'"

        googleSearch.search_term = term
        googleSearch.click_search_button


        # Expected Result :
        #   Results are displayed

        assert(googleSearchResults.displayed?, "The Google search results page is not displayed")
        
        puts googleSearchResults.result_stats
        
        assert_not_nil(googleSearchResults.result_stats, "The Google search results page did not display any result-stats")
        assert_not_empty(googleSearchResults.result_stats, "The Google search results page did not display any result-stats")


    end

end
