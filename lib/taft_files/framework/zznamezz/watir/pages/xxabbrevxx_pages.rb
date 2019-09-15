# Class that holds definitions for all of the pages in ZZnamezz
# These can be used to determine if the browser is currently displaying that page

require_relative 'page_objects'

class XXabbrevupperxxPages

  attr_accessor :browser # the browser object
  attr_accessor :pages # array of Page objects
  attr_accessor :page_names # array of names of known Page objects

  def initialize(browser)
    @browser = browser
    @pages = [] # an array of Page objects
    @page_names = []

    # Nav bar
    # Not a real page, but is a panel common to many pages
    # Don't add_page(nav_bar); do page.add_page(nav_bar)
    nav_bar = Page.new("xxabbrevxxNavBar", "page_title", "Welcome to ZZnamezz")
    
    nav_bar.add_field("goto_homepage", :link, :id, "xxabbrevxx_home_header_link")
    nav_bar.add_field("page_title", :h1, :id, "page_title")

    # Homepage
    page = Page.new("xxabbrevxxHomepage", "page_title", "Welcome to ZZnamezz")
    
    page.add_field("all_users", :link, :id, "users_header_link")
    page.add_page(nav_bar)

    add_page(page)


    # Users
    page = Page.new("xxabbrevxxUsers", "page_title", "Listing users")
    
    page.add_field("users", :table, :id, "view_users_table")
    page.add_field("new_user", :link, :id, "new_user_link")
    page.add_page(nav_bar)

    add_page(page)

    # Create User
    page = Page.new("xxabbrevxxCreateUser", "page_title", "New user")
    
    page.add_field("user_name", :text_field, :id, "user_name")
    page.add_field("role", :list, :id, "user_role")
    page.add_field("save", :button, :id, "save")
    page.add_field("back", :link, :id, "back_link")
    page.add_page(nav_bar)

    add_page(page)

    # View User
    page = Page.new("xxabbrevxxViewUser", "page_title", /^User/)

    page.add_field("project", :div, :id, "name")
    page.add_field("version", :div, :id, "roles")
    page.add_field("edit", :link, :id, "edit_link")
    page.add_field("back", :link, :id, "back_link")
    page.add_page(nav_bar)

    add_page(page)
 
  end

##################################################################################################


  def add_page(page)
    page.browser = @browser # set the browser object for each page
    # TODO have only one browser object (here in XXabbrevupperPages), and have each page know how to find it, instead of taking
    # their own copy of the object
    @pages << page
    @page_names << page.name
  end

  # TODO needed?
  def ==(o)
  end

  # TODO needed?
  def to_s
    s = ""
    s += "#{@pages.size} pages defined. Names :"
    @page_names.each {|f| s += "\n#{f}" }
    s
  end

  # Will convert name to a string
  def page_known?(name)
    @page_names.include?(name.to_s)
  end

  # Retrieves the specific page; raises if it cannot be found
  # Will convert name to a string
  def find(name)
    raise "Could not locate page '#{name}'" unless page_known?(name)
    @pages[@page_names.index(name.to_s)]
  end
end

