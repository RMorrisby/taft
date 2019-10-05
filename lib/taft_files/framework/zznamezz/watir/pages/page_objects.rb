# Base class that every defined page will inherit from
class Page

  attr_accessor :name, :displayed_field, :displayed_value
  attr_accessor :browser
  attr_accessor :field_parameters_array # stores parameters of each field added to the page

  # Name : the name of this page, e.g. rsHomepage
  # Field : the field used to determine if the page is displayed. More precisely,
  # the name of the method that accesses the field. E.g. if the page has a field called 'page_title' 
  # defined, then its accessor method 'page_title_field' will have been generated .
  # If the displayed? check is against an expected value, specify the field name corresponding to 
  # the read-method (e.g. page_title), and specify the value (String or Regexp).
  # If the displayed? check is for a field to exist, specify the field's accessor method name 
  # (e.g. page_title_field), and keep value nil.
  def initialize(name, field, value = nil)
    @name = name
    @displayed_field = field
    @displayed_value = value
    @field_parameters_array = []
  end

  def displayed?(wait = true)
    displayed = false
    puts "in displayed? for page #{@name}"
    if wait
      puts "will wait for page to be loaded"
      wait_until_displayed
    end
    
    puts "about to send to #{@displayed_field.to_sym.inspect}"
    begin
      field_or_value = self.send(@displayed_field.to_sym)
    rescue Watir::Exception::UnknownObjectException
      # cannot find the field on the page
      # do nothing, displayed will stay false
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      # TODO : fix! wait then call displayed? again?
      puts "hit StaleElementReferenceError for page #{@name}"
    end

    puts "field_or_value retrieved is of class #{field_or_value.class}"
    p field_or_value
    if @displayed_value == nil
      displayed = true if field_or_value.exists?
    else
      if @displayed_value.class == Regexp
        displayed = true if field_or_value =~ @displayed_value
      else
        displayed = true if field_or_value == @displayed_value
      end
    end
    displayed
  end

  # Method to wait for the page to be displayed, up to <timeout> seconds
  # Returns displayed status (true/false)
  def wait_until_displayed(timeout = 5)
    max = timeout * 10
    count = 0
    displayed = false
    while count < max
      displayed = displayed?(false)
      break if displayed
      sleep 0.2
      count += 2
    end
    displayed
  end

  # Defines methods to access the field of specified type, by specified key & value
  def add_field(name, type, key, value)
    field_parameters_array << [name, type, key, value]
    add_field_using_constructor_class(name, type, key, value)
  end
  
  # Add to self all fields that were defined on page_object
  # E.g. the supplied page_object represents part of a panel/page that is common to several pages
  def add_page(page_object)
    page_object.field_parameters_array.each do |field_parameters|
      add_field(field_parameters[0], field_parameters[1], field_parameters[2], field_parameters[3])
    end
  end

  # Defines methods to access the field of specified type, by specified key & value
  def add_field_using_constructor_class(name, type, key, value)
    PageFieldConstructor.add_fields(self, name, type, key, value)
  end

end # end Page

class PageFieldConstructor

  # Defines methods to access the field of specified type, by specified key & value
  def PageFieldConstructor.add_fields(page_object, name, type, key, value)

    # Fields cannot have the following names : name
    raise "Field on page #{page_object.name} with name of #{name} is not allowed" if ZZnamezzConfig::DISALLOWED_FIELD_NAMES.include?(name)
    
    case type
    when :button
      real_type = :input
    else
      real_type = type
    end
    
    # add accessor to field
    s = <<-METHOD
    def page_object.#{name}_field
#      puts "in #{name} method"
      @browser.#{real_type}(#{key.inspect} => "#{value}")
    end    
    METHOD
    #    page_object.class.module_eval(s) # do not do this - want to add methods (field) to the object, not the class!
    eval(s)

    case type
      when :text_field
        add_read_method(page_object, name)
        add_write_method(page_object, name)
      when :button
        add_click_method(page_object, name)
      when :link
        add_read_method(page_object, name)
        add_click_method(page_object, name)
      else
        add_read_method(page_object, name)
    end

  end

  def PageFieldConstructor.add_read_method(page_object, name)
    s = <<-READ
        def page_object.#{name}
#          puts "in #{name} read method"
          #{name}_field.text # value
        end    
    READ
    #    page_object.class.module_eval(s) # do not do this - want to add methods (field) to the object, not the class!
    eval(s)
  end

  def PageFieldConstructor.add_write_method(page_object, name)
    s = <<-WRITE
        def page_object.#{name}=(v)
#          puts "in #{name} write method"
          #{name}_field.set(v) 
        end    
    WRITE
    #    page_object.class.module_eval(s) # do not do this - want to add methods (field) to the object, not the class!
    eval(s)
  end

  def PageFieldConstructor.add_click_method(page_object, name)
    s = <<-CLICK
        def page_object.click_#{name}
#          puts "in #{name} click method"
          #{name}_field.click
        end    
    CLICK
    #    page_object.class.module_eval(s) # do not do this - want to add methods (field) to the object, not the class!
    eval(s)
  end

end

