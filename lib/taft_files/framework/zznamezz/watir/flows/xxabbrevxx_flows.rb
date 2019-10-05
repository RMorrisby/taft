# A class defining the UI flows within ZZnamezz, such that simple usecase-esq methods arise from them and can
# perform a series of UI actions (making a record, viewing & deleting, etc.)

# The intended use is that the test (or supporting framework) call @flow.flow_name, e.g. @flow.create_project, which will
# perform all of the actions of that flow. Parameters can be supplied to the call, which will change its behaviour

require_relative 'flow_objects'
require_relative 'xxabbrevxx_flow_names'

class XXabbrevupperxxFlows

  attr_accessor :flows # array of Flow objects
  attr_accessor :flow_names # array of names of known Flow objects


  # Assembles all of the flows and stores them, ready for use
  def initialize
    @flows = [] # an array of Flow objects
    @flow_names = []

    # Simple nav flow to get to the homepage
    flow = Flow.new(XXabbrevupperxxFN::GOTO_HOMEPAGE)
    flow.add(FlowLink.new("goto_homepage", "xxabbrevxx_home_header_link", nil)) # no parent page, is valid from any page
    add_flow(flow)

    # View all users
    flow = new_base_flow(XXabbrevupperxxFN::VIEW_ALL_USERS)
    flow.add(FlowLink.new("all_users", "users_header_link", nil))
    add_flow(flow)

    # Create user
    flow = new_base_flow(XXabbrevupperxxFN::CREATE_USER)
    add_existing_flow_to_flow(flow, XXabbrevupperxxFN::VIEW_ALL_USERS)

    flow.add(FlowLink.new("all_users", "users_header_link", nil))
    flow.add(FlowLink.new("create_user", "new_user_link", "all_users"))
    field_flow = Flow.new("create_user_fields")

    field_flow.add(FlowField.new("user_name"))
    field_flow.add(FlowField.new("user_role", :list, :write, true, nil, ZZnamezzConfig::ALL_USER_ROLES))
    
    flow.add(field_flow)
    flow.add(FlowField.new("save", :button))

    message = FlowField.new("notice", :p, :read)
    flow.add(FlowVerify.new(true, "User was successfully created.", message))

    add_flow(flow)
  end


  ##############################################################################

  
  def method_missing(name, *args, &block)
    puts "XXabbrevupperxxFlows method_missing called; name = #{name.inspect}; #{name.class}"

    if flow_known(name)
      puts "Flow #{name} is known"
      # TODO define a whole bunch of methods and then perform them
      # If args and/or block have been provided, process them. E.g. one arg could be a trigger to perform the flow with
      # invalid values # TODO : is that the best way of doing that?
    else
      super
    end
  end

  def add_flow(flow)
    @flows << flow
    @flow_names << flow.name
  end

  # TODO needed?
  def ==(o)
  end

  # TODO needed?
  def to_s
    s = ""
    s += "#{@flows.size} flows defined. Names :"
    @flow_names.each {|f| s += "\n#{f}" }
    s
  end

  # Will convert name to a string
  def flow_known?(name)
    @flow_names.include?(name)
  end

  # Retrieves the specific flow; raises if it cannot be found
  # Will convert name to a string
  def find(name)
    raise "Could not locate flow '#{name}'" unless flow_known?(name)
    @flows[@flow_names.index(name)]
  end
  
  # Finds & executes a flow
  def find_and_execute(browser, name, custom_values_hash = {}, success_sym = :success, mandatory_fields_sym = :mandatory)
    f = find(name)
    f.execute(browser, custom_values_hash, success_sym, mandatory_fields_sym)
  end

  # Adds an already-existing flow to the supplied flow
  def add_existing_flow_to_flow(new_flow, existing_flow_name)
    # TODO : need deduplication mechanism so that a flow doesn't gain two/more duplicate flow items in a row (e.g. two calls to GOTO_HOMEPAGE in a row)
    new_flow.add(find(existing_flow_name))
  end

  # Shortcut to define a new flow with standard prerequisite flows already added
  # Cannot be called until the flows that are to be added have been defined
  def new_base_flow(name)
    flow = Flow.new(name)
    add_existing_flow_to_flow(flow, XXabbrevupperxxFN::GOTO_HOMEPAGE)
    flow
  end

end
