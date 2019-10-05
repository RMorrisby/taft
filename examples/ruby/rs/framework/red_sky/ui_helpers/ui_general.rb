
class RSHelper

    def new_browser_at_url(url)
        puts "New browser at #{url}"
        case RedSkyConfig::BROWSER
        when :chrome
            # Set detach to true so the browser remains open once the test finishes
            options = Selenium::WebDriver::Chrome::Options.new
            options.add_option(:detach, true)
            b = Watir::Browser.new :chrome, :options => options

        when :firefox
            b = Watir::Browser.new :firefox

        end

        b.goto url

        # Store the new browser in the global list
        $browsers << b

        b # return the browser
    end

    def ui_helper_test
        puts "in #{__method__}"
    end
       
    # Simple method to show that @help can access the browser
    def enter_google_term(term)
        googleSearch.search_term = term
        puts "@help set term"
    end

end
