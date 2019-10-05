# Class that holds definitions for all of the pages in RedSky
# These can be used to determine if the browser is currently displaying that page
#
# Field types :
# Use :text_field instead of :input if it's a text-field
# Use :button instead of :input if it's a button
# Otherwise, use the actual HTML element type

require_relative 'page_objects'

class RSPages

  @@browser = nil
  @@pages = [] # an array of Page objects
  @@page_names = []

  def self.make_pages(browser)
    @@browser = browser

    # Google Search
    page = Page.new("googleSearch", "search_term_field")

    page.add_field("search_term", :text_field, :name, "q")
    page.add_field("search_button", :button, :name, "btnK")

    self.add_page(page)
 
    
    # Google Search Results
    page = Page.new("googleSearchResults", "result_stats_field")

    page.add_field("result_stats", :div, :id, "resultStats")

    self.add_page(page)
  end

##################################################################################################


  def self.add_page(page)
    page.browser = @@browser # set the browser object for each page
    # TODO have only one browser object (here in RSPages), and have each page know how to find it, instead of taking
    # their own copy of the object
    @@pages << page
    @@page_names << page.name
  end

  # Outputs info on the pages currently stored
  def self.info
    s = ""
    s += "#{@@pages.size} pages defined. Names :"
    @@page_names.each {|f| s += "\n#{f}" }
    s
  end

  # Will convert name to a string
  def self.page_known?(name)
    @@page_names.include?(name.to_s)
  end

  # Retrieves the specific page; raises if it cannot be found
  # Will convert name to a string
  def self.find(name)
    raise "Could not locate page '#{name}'" unless self.page_known?(name)
    @@pages[@@page_names.index(name.to_s)]
  end
end

