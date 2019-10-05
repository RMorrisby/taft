
class XXabbrevupperxxHelper

    def new_browser_at_url(url)
        puts "New browser at #{url}"
        case ZZnamezzConfig::BROWSER
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

end