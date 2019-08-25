
# This file defines a module to be included in all test cases for the testing of yyrawnameyy.
# This module contains a general setup and teardown method that each test should run.
# If tests wish to perform their own specific seup and/or teardown routines, they 
# should implement their own methods and call super within them to trigger these common
# setup/teardown methods at the right time.

$LOAD_PATH.unshift File.dirname(__FILE__) + "/..")

gem 'test-unit'
require 'test/unit'
require 'tmpdir'
require 'time'
require 'fileutils'
require 'timeout'

# Config
require 'config/zznamezz_config'

# Helpers
require 'framework/zznamezz.rb'



STDOUT.sync = true

if ZZnamezzConfig::WRITE_CI_REPORTS
    require 'ci/reporter/rake/test_unit_loader'
    
    ENV["CI_REPORTS"] = $CI_REPORTS_PATH # supplied in invokation to test
    puts "Will create XML reports in #{ENV["CI_REPORTS"]}"
end

module ZZnamezzTestCase

    include ZZnamezz

    attr_accessor :browser_has_been_opened

    # optional field
    # If the cause of a test's failure is already likely to be known, the contents of this variable 
    # will automatically be added to the test result's Notes field, to help with reporting.
    # If there are multiple tests in a file, this variable needs to be set within each test 
    # method (if they have any relevent failure notes).
    attr_accessor :failure_notes

    # By default, unknown methods (e.g. xxabbrevupperxxPage names) are sent to the different contexts 
    # for resolution. This allows pages to be accessed as xxabbrevxxHomePage rather than
    # @xxabbrevxx_context.xxabbrevxxHomePage
    def method_missing(meth, *args)
        case meth.to_s
        when /^xxabbrevxx/
            @xxabbrevxx_context.send(meth, *args)
#        when /^some_other_app/
#            @some_other_app_context.send(meth, *args)
        else
            super
        end
    end


    if $WRITE_RESULTS # supplied from invokation
        WRITE_RESULTS = true
    else
        WRITE_RESULTS = false
    end

    # Close the current browser and log in again
    def re_login
        browser.close

        new_browser_on_login_page
        # Reinitialise the contexd and @help
        reinitialisexxabbrevupperxxContext(browser)
    end

    # Connect to yyrawnameyy and reinitialise the context, etc.
    def xxabbrevxx_login(url = ZZnamezzConfig::SERVER[:zznamezz_url])
        puts url
        new_browser_on_login_page(url)
        reinitialisexxabbrevupperxxContext(browser)
    end

    # Reinitialise xxabbrevupperxx context only
    def reinitialisexxabbrevupperxxContext(new_browser)
        @xxabbrevxx_context = ZZnamezz::Context.new(new_browser)
        @help = xxabbrevupperxxHelper.new(@xxabbrevxx_context)
    end

    # Return to the previous xxabbrevupperxx session
    def return_to_xxabbrevxx
        self.browser = @xxabbrevxx_context.browser
    end

    # Close the current browser
    def close_browser
        self.browser.close
    end

    def close(browser)
        if browser.exists? && ((ZZnamezzConfig::CLOSE_BROWSER_AFTER_TEST && passed?) || ZZnamezzConfig::FORCE_CLOSE_BROWSER_AFTER_TEST)
            browser.close
            $browsers.delete_at($current_browser_position - 1) # array indexing
            self.browser = $browsers[-1] # set browser to the last one that is still in the array
        end
    end

    def close_all_browsers
        if (ZZnamezzConfig::CLOSE_BROWSER_AFTER_TEST && passed?) || ZZnamezzConfig::FORCE_CLOSE_BROWSER_AFTER_TEST
            until $browsers.empty?
                self.browser = $browsers.shift
                browser.close
            end
        end
    end

    # Ensure that every test (that wants one) has a browser that is already logged in to the system
    def setup

        Watir.always_locate = true # default is true; setting to false speeds up Watir to a degree

        # Get start time for later output in results
        @test_start_time = Time.now

        # Get the directory that the specific test lives in, so that it can be included in the results file
        @test_file_dir = @test_file.split(File::SEPARATOR)[-2]

        # Select default certificate if none is configured
        @certificate ||= :regular

        @timeout = ZZnamezzConfig::CERTIFICATE_POPUP_TIMEOUT

        # Open the browser & ensure page contenxt and helper are available
        $browsers = [] # global array containing all browser objects
        # $current_browser_position = nil # global variable to track the position in $browsers of the active browser # TODO used?
        # When that browser is closed, we can ensure that the corresponding browser object is removed from the array
        if @initialBrowser == :xxabbrevxx
            xxabbrevxx_login
        elsif (@initialBrowser == :none || @initialBrowser == nil)
            browser = nil
            reinitialisexxabbrevupperxxContext(browser)
        end

    end # end setup

    # Close all browsers and write the result of the test to the results CSV
    def teardown

        begin
            # Get end time
            @test_end_time = Time.now
            elapsed_time = (@test_end_time - @test_start_time).to_s
            elapsed_time_in_minutes = (elapsed_time.to_i/60.0).to_s

            test_name = self.to_s.split("(")[0] # self.to_s gives output like test_ABC5_01(TC_ABC5_01)

            puts "Test has now finished; #{test_name} : #{passed?}"

            if WRITE_RESULTS
                puts "Will now write results to #{ZZnamezzConfig::RESULTS_BASE_DIR}"

                notes = ""
                success_text = passed? ? ZZnamezzConfig::PASSED : ZZnamezzConfig::FAILED

                unless passed?
                    begin
                        if ZZnamezzConfig::MAKE_ERROR_SCREENSHOTS
                            puts "Now taking error screenshots"
                            dir_2 = ZZnamezzConfig::ERROR_SCREENSHOT_LOCATION
                            Dir.mkdir(dir_2) unless File.exists?(dir_2)
                            $browsers.each do |browser|
                                browser.screenshot.save(ZZnamezzConfig::ERROR_SCREENSHOT_LOCATION + "/#{test_name}_Time_#{@test_end_time.strftime("%H-%M-%S")}_Browser_#{$browsers.index(browser)}.png")
                            end
                        end
                    rescue
                        puts "Failed to make screenshot"
                    end
                    notes = @failure_notes
                    puts "Notes : #{notes}"
                end # end unless passed?

                close_all_browsers

                # Write to the results file
                begin
                    File.open(ZZnamezzConfig::RESULTS_CSV, "a") do |f|
                        row = [@test_file_dir, test_name, success_text, @test_start_time.strftime("%Y-%m-%d %H:%M:%S"), @test_end_time.strftime("%Y-%m-%d %H:%M:%S"), elapsed_time, elapsed_time_in_minutes, notes]
                        f.puts row.join(",")
                        puts "Result for test #{test_name} written"
                    end
                rescue
                    puts "Had to rescue from writing results to file #{ZZnamezzConfig::RESULTS_CSV}"
                end
            end # end if WRITE_RESULTS
        rescue Timeout::Error => t_error
            puts "Timeout::Error :"
            puts t_error
            puts "Backtrace :"
            puts t_error.backtrace
        rescue Exception => error
            puts "Error :"
            puts error
            puts "Backtrace :"
            puts error.backtrace
        end # end begin
    end



end


