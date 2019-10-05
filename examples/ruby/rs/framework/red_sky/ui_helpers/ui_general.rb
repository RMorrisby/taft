


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
            # TODO

        end

        b.goto url

        # Store the new browser in the global list
        $browsers << b

        b # return the browser
    end

    def ui_helper_test
        puts "in #{__method__}"
    end
       
    # Simplen method to show that @help can access the browser
    def do_google_stuff(term)
        googleSearch.search_term = term
        puts "@help set term"
    end

end
