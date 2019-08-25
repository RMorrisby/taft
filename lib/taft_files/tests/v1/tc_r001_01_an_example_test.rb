$LOAD_PATH.unshift("#{File.expand_path(File.dirname(__FILE__))}/../../lib")

require "zznamezz_test_case"

class TC_R001_01_AN_EXAMPLE_TEST < Test::Unit::TestCase
    include ZZnamezzTestCase
    
    def setup
        # specify setup parameters
        @certificate = :regular # this is the default user for this test
        @initialBrowser = :none # if you want this test to navigate to your webapp automatically as part of setup, change this value to the value referring to your webapp

        super # must call super so that the common setup method in ZZnamezzTestCase is called
    end

    def test_r001_01_an_example_test

        ############################################################################################
        # PURPOSE :
        #   Verify that <description of your test's intent>
        # 
        # PRECONDITIONS :
        #   <list your preconditions>
        ############################################################################################

        filename = "data_for_example_test.csv" # file must be in the data/ directory
        data = @help.read_csv_test_data(filename)
        header = data.shift

        # Step 1 :
        #   Send a request to the yyrawnameyy API Options method

        random_row = data.random
        search_term = random_row[0]
        expected_result_count = random_row[1]

        # This is too raw - it would be better to bundle these lines into a separate "search_options" method,
        # with additional validation (e.g. to throw a clean error if the request failed)
        @client = @help.get_rest_client(:options, @certificate, search_term)
        json = client.get
        response = JSON.pretty_unparse(json)

        # Expected Result :
        #   The request has succeeded & returned the expected results

        # This is quite brittle
        # A better approach is to create a new class which would parse the response & convert
        # it into a bespoke Object, so that the various values could be accessed in a better OO-fashion.
        # E.g. response.number_of_results. The object could also have extra methods, 
        # e.g. response.check_results_are_valid, and so on.
        assert_equal(expected_result_count, response["number_of_results"], "The search request did not return the expected number of results")

        
        # Step 2 :
        #   Log in to yyrawnameyy

        xxabbrevxx_login

        # Expected Result :
        #   The yyrawnameyy homepage is displayed

        assert(xxabbrevxxHomepage.displayed?, "The yyrawnameyy homepage is not displayed")

        
        # Step 3 :
        #   Enter in a search term and click the Search button.

        data.each do |row|
            search_term = row[0]
            expected_result_text = row[2]
            puts "Will now search for '#{term}'; expect to see '#{expected_result_text}'"

            xxabbrevxxHomepage.term = search_term
            xxabbrevxxHomepage.click_search


            # Expected Result :
            #   Results are displayed

            assert(xxabbrevxxSearchResults.displayed?, "The yyrawnameyy search results page is not displayed")
            assert_equal(expected_result_text, xxabbrevxxSearchResults.result, "The yyrawnameyy search results page did not display the expected result")

        
            # Step 4 :
            #   Return to the previous page

            browser.back



            # Expected Result :
            #   The yyrawnameyy homepage is displayed
            
            assert(xxabbrevxxHomepage.displayed?, "The yyrawnameyy homepage is not displayed")

            
            # Step 5 :
            #   Repeat steps 3 and 4 for a few more search terms

            # Actions performed in above steps


            # Expected Result :
            #   Results are displayed for each term

            # Assertions performed in above steps
   
        end # end .each

    end

end