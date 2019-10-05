# A class defining the series of Flow classes & helpers

# TODO define some base class/classes. Must be scope here for consolidation through inheritance?

#require 'minitest/unit' # needed? # TODO use test-unit, or convert everything else to minitest

#class FlowObjects
#  attr_accessor :flows
#
#  def initialize
#    @flows = [] # an array of Flow objects
#  end
#
#  def add_flow(flow)
#    @flows << flow
#  end
#
#  # TODO needed?
#  def ==(o)
#  end
#
#  # TODO needed?
#  def to_s
#  end
#
#end

# A class defining a flow. This contains the fields to be interacted with, in their proper sequence, with valid or
# invalid values
class Flow

  attr_accessor :name
  attr_accessor :flow_map # some collection of Flow, FlowField & other Flow-type objects # TODO

  def initialize(name)
    @name = name
    @flow_map = []
  end

  def add(flow_item)
    @flow_map << flow_item
  end

  # TODO needed?
  def ==(o)
  end

  def to_s
    s = ""
    s += "Flow name : #{@name}. Flow map size : #{@flow_map.size}. Flow items :"
    @flow_map.each {|f| s += "\n\t#{f.to_s}" }
    s
  end

  # Executes the flow
  # Takes symbols which act as flags :
  # success_sym - set to :success for a valid set of inputs, set to :fail for one or more of the inputs to be invalid and
  # the flow to fail
  # mandatory_fields_sym - set to :mandatory to only involve the mandatory fields, set to :all_fields to use all defined
  # fields in the flow
  # custom_values_hash - hash of values some/all of the fields must take (e.g. creating a new record with a specific foreign key)
  # keys are field names (as defined in CeresFlows) in either symbol or string form, values are the values the fields should take
  # TODO : don't want to have to pass in browser each time
  def execute(browser, custom_values_hash = {}, success_sym = :success, mandatory_fields_sym = :mandatory)
    report = nil # if report is still nil at the end of the method, generate a dummy one
    return_value = nil # default value that will be fed into the report # TODO needs to be an array? Or hold multiple
    # values?
    #    pass = true
    #    all = true
    case success_sym
      when :success
        pass = true
      when :fail
        pass = false
      else
        raise "Did not understand value '#{success_sym.inspect}' for success_sym"
    end

    case mandatory_fields_sym
      when :mandatory
        all = false
      when :all_fields
        all = true
      else
        raise "Did not understand value '#{mandatory_fields_sym.inspect}' for mandatory_fields_sym"
    end

    @flow_map.each do |flow_item|
      case flow_item
        when Flow # flows can contain sub-flows
          flow_item.execute(browser, custom_values_hash, success_sym, mandatory_fields_sym) # call recursively
        when FlowPrecondition
          # TODO : find flow from name & execute it
          flow_item.execute_precondition_flow(custom_values_hash)
        when FlowLink
          # debugging
          #          puts "Executing #{flow_item.name}"
          #          puts browser.url

          browser.link(:id => flow_item.name).click

          sleep 1 # TODO determine expected page, call page.wait_until_displayed
        when FlowField
          puts "Now executing field #{flow_item.to_s}"
          next if all == false && flow_item.mandatory == false # skip optional fields if instructed

          field = nil
          
          # TODO : look up field identification parameters (e.g. :id => something) from field definition in xxabbrevxx_pages
          #        The linkage should be that the NAME of the xxabbrevxx_page field (e.g. page.add_field("role", :list, :id, "user_role") )
          #        matches the NAME of the flow_item. We therefore use flow_item.name to track down the field identification parameters
          #        stored in the field definition in xxabbrevxx_pages (in this example, :id, "user_role" )
          # Until this is done, flow_item.name needs to match the xxabbrevxx_pages field ident param.
          
          case flow_item.type
            # TODO only have this case statement determine field type, then pass it into one eval line instead of one
            # line per type
            # Type field completion may differ by more than just their field type...

            when :string
              field = browser.text_field(:id => flow_item.name)
            when :p
              field = browser.p(:id => flow_item.name)
            when :div
              field = browser.div(:id => flow_item.name)
            when :checkbox
              field = browser.input(:id => flow_item.name)
            when :list
#              field = browser.select_list(:id => flow_item.name)
              field = browser.select(:id => flow_item.name)
            when :button
              # buttons only have one function - to be pressed, not to be read or written to
              browser.button(:id => flow_item.name).click
            else
              raise "Cannot execute #{flow_item.class} of type #{flow_item.type}"
          end
          case flow_item.operation
            when :read
              case flow_item.type
                when :string, :checkbox, :list, :p, :div
#                  puts "value : #{field.value}"
#                puts "text : #{field.text}"
                  return_value = field.value
                return_value = field.text if return_value == "" # p needs .text
#                  puts "return_value : #{return_value}"
              end
            when :write
              # get valid value from hash, if it has been specified
              value = custom_values_hash[flow_item.name.to_sym].to_s # flow_item.name is defined in xxabbrevxx_flows to be a string; it is nicer if the custom hash keys are symbols, but we then need to convert them
              value = flow_item.random_valid_value if value == nil
              #        value = flow_item.random_invalid_value if invalid # TODO enable
              case flow_item.type
                when :string, :checkbox
                  field.set(value)
                when :list
                  field.select(value)
              end
          end
        when FlowVerify
          name = "verify"
          verify_flow = Flow.new(name)
          verify_flow.add(flow_item.flow_field)
          # call recursively, have it generate a Report, perform validation against the Report
          report = verify_flow.execute(browser)
#puts "report : #{report}"
          value = report.value
          flow_item.verify(value)
          return_value = "FlowVerify passed : #{flow_item}"
        when FlowReport # not yet in use - no FlowReports have been defined in xxabbrevxx_flows
          report = flow_item.generate_report
        else
          raise "Cannot execute flow item of class #{flow_item.class}"
      end # end case
    end # end .each
    if report == nil # if report is still nil at the end of the method, generate a dummy one
      #      return_value =
      report = FlowReport.new(return_value)
    end
    report
  end # end execute

end # end class

# A class defining a flow that must be executed as a precondition to the flow this object belongs to
class FlowPrecondition

  attr_accessor :precondition_flow # precondition_flow is the name of the precondition flow that must be executed

  def initialize(precondition_flow)
    @precondition_flow = precondition_flow
  end

  def to_s
    s = ""
    s += "Precondition Flow : #{@precondition_flow}"
    s
  end

  # TODO : need success & madatory field flags here?
  def execute_precondition_flow(custom_values_hash = {})
    # find flow from name
    # TODO : flows all stored in @flow (CeresFlow.new()). Gaining access to this feels wrong...

    # execute flow

  end

end

# A class defining a navigation step that is needed as part of a flow. These assume that their navigation is done via
# links, not buttons/divs/etc.
class FlowLink

  attr_accessor :name, :parent_page, :destination, :verification # parent_page is the page within which the desired link
  # can be found
  # destination is the name of the page that the browser will arrive at after performing this navigation.
  # verification is a FlowVerify object that is defined such that it can only pass if it matches the defined field on the
  # destination page
  # TODO enable mechanism such that one can simply state flow.goto(destination) and all flows will be scanned for the
  # flow that will take us there, then that flow will be executed.

  def initialize(destination, name, parent_page)
    @destination = destination
    @name = name
    @parent_page = parent_page
  end

  def to_s
    s = ""
    s += "Flow destination : #{@destination}. Link ID : #{@name}. Parent page : #{@parent_page}"
    s
  end

end

# A class defining a field that is interacted with in some way as part of a flow.
# Valid types: :string (a text field); :button (a button); :link (a link); :list (a select list); :checkbox (a checkbox)
# TODO still want link to be valid here? What about FlowLink?
class FlowField

  attr_accessor :name, :type, :operation, :mandatory, :size, :custom_valid_value_definition, :custom_invalid_value_definition

  def initialize(name, type = :string, operation = :write, mandatory = true, size = nil, custom_valid_value_definition = nil, custom_invalid_value_definition = nil)
    raise "FlowField name must be a string" unless name.class == String
    @name = name
    @type = type
    @operation = operation
    raise "Cannot define FlowField #{@name} with operation of #{@operation.inspect}" unless @operation == :read || @operation == :write
    @mandatory = mandatory
    if size == nil
      @size = get_default_size
    else
      @size = size
    end
    
    custom_valid_value_definition = nil
    custom_invalid_value_definition = nil

    check_valid_type

    # TODO custom_valid_value_definition, etc
    case custom_valid_value_definition
      when NilClass
        #  take default valid field def based on @type
      when Symbol
        #run sub-case based on symbol
      when Regexp # ?
        #  define method
      when Array
        @custom_valid_value_definition = custom_valid_value_definition
      when block # ?
        #  define method
      else
        raise "Could not process custom_valid_value_definition specified for FlowField of name '#{@name}'"
    end

    case custom_invalid_value_definition
      when NilClass
        #  take default valid field def based on @type
      when Symbol
        #run sub-case based on symbol
      when Regexp # ?
        #  define method
      when Block # ?
        #  define method
      else
        raise "Could not process custom_invalid_value_definition specified for FlowField of name '#{@name}'"
    end
  end

  # Retrieves default sizes for fields
  # Assumes @type is set
  def get_default_size
    size = 0
    case @type
      when :button, :link, :list, :checkbox
        # do nothing
      when :string
        size = 32
      when :p, :div # these will be read-only so this doesn't really matter
        size = 4000
      else
        raise "#{@type} is not a valid type for FlowField"
    end
    size
  end

  # Valid types:
  # :string (a text field);
  # :button (a button);
  # :link (a link);
  # :list (a select list);
  # :checkbox (a checkbox)
  def check_valid_type
    case @type
      when :button, :link, :list, :checkbox
        check_valid_size(0)
      when :string, :p, :div
        check_valid_size(@size) # TODO a pointless call - @size will compared against itself!
      else
        raise "#{@type} is not a valid type for FlowField"
    end
  end

  # Raises unless the supplied size is greater or equal to @size
  def check_valid_size(valid_size_for_type)
    valid = false
    case @size
      when NilClass
        valid = true if @size == nil
      when TrueClass # possible?
        valid = @size if something # TODO
      when FalseClass # possible?
        valid = @size if something # TODO
      when Fixnum, String
        valid = true if @size <= valid_size_for_type
    end

    raise "Defined size #{@size.inspect} for FlowField '#{@name}' is not valid for field of type '#{type}'" unless valid
  end

  # TODO needed?
  def ==(o)
  end

  # TODO needed?
  def to_s
    s = ""
    s += "Flow field : #{@name}. Type : #{@type}. Mandatory : #{@mandatory}. Size : #{@size}"
    s
  end

  # Generate a random value based on its type
  def random_valid_value
    value = nil
    case @type
      when :string
        value = rand_string(@size) # TODO : vary size of random string?
      when :checkbox
        #      value = (rand(2) == 1) # TODO : need to have the object itself have defined what is a valid and invalid
        # value
        value = true # most checkboxes will want to be ticked, but it is plausable that the valid value for some of them
        # is to be unticked
      when :list
        # TODO difficult - need to pick a random item from the list. How do we know its contents?
        # Maybe pick a random number, not greater than the size of the list, then set by index/position?
        if @custom_valid_value_definition != nil # if not nil, custom_valid_value_definition should be an array of the valid options
          value = @custom_valid_value_definition.random
        end
      when :button
        # do nothing
      else
        raise "Do not know how to generate a random valid value for FlowField of type #{@type}"
    end
    value
  end

end

# A class defining a verification step
class FlowVerify

  include Test::Unit::Assertions

  attr_accessor :expected, :value_or_regex, :flow_field
  # expected is a boolean for whether or not the verification is expected to succeed or fail
  # value_or_regex is a string, number, boolean or regex
  # flow_field is a FlowField object pointing to a field whose value value_or_regex must be used against

  def initialize(expected, value_or_regex, flow_field)
    @expected = expected
    @value_or_regex = value_or_regex

    @flow_field = flow_field
    raise ":flow_field must be of class FlowField" unless @flow_field.class == FlowField
  end

  def to_s
    s = ""
    s += "Flow verifier : expected : #{@expected}. Value/regex : #{@value_or_regex.inspect}. Field : #{@flow_field}"
    s
  end

  def verify(actual)
    puts "now in verify for FlowVerify for field #{@flow_field} against value #{@value_or_regex}"

    case @value_or_regex # case is better, leaves room for other options depending on class
      when Regexp
        match = !!(actual =~ @value_or_regex) # double-invert to convert to true-or-false
      else
        match = (actual == @value_or_regex)
    end
    if @expected
      message = "FlowVerify failed. Expected the value to match #{@value_or_regex.inspect} but was actually #{actual.inspect}"
    else
      message = "FlowVerify failed. Expected the value #{@value_or_regex.inspect} to be different to the actual value of #{actual.inspect}"
    end
    puts "about to assert; #{actual.inspect} == #{@value_or_regex.inspect} => #{@expected == match}"
    assert_equal(@expected, match, message)
    puts "assertion passed"
  end

end

# A class defining feedback to be returned after invoking the flow.
# TODO : rework this so that it knows how to gather the required information (?)
class FlowReport

  #  attr_accessor :success, :message, :value_hash_array
  #  # success is a boolean
  #  # message is a string
  #  # value_hash_array is an array of hashes, one per object/event/thing. Its keys are the object's fields, and the
  # values
  ## are their values
  #
  #  def initialize(success, message, value_hash_array)
  #    @success = success
  #    @message = message
  #    @value_hash_array = value_hash_array
  #  end
  #
  #  def to_s
  #    s = ""
  #    s += "Flow report : success? #{@success}. Message : #{@message}. Values : #{@value_hash_array}"
  #    s
  #  end

  attr_accessor :value

  def initialize(value = nil)
    # do nothing?
    @value = value
  end

  def to_s
    s = ""
    s += "Flow report : value : #{@value}"
    s
  end

  def generate_report
    #TODO
    ""
  end

end