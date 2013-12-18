class MassObject

  # takes a list of attributes.
  # creates getters and setters.
  # adds attributes to whitelist.
  def self.my_attr_accessible(*attributes)
    @white_list ||= []
    @white_list.concat(attributes)
    my_attr_accessor(*attributes)
  end

  def self.my_attr_accessor(*var_names)
    var_names.each do |var_name|
      define_method(var_name) do
        instance_variable_get("@#{var_name}")
      end

      define_method("#{var_name}=") do |value|
        instance_variable_set("@#{var_name}", value)
      end
    end
  end
  
  # returns list of attributes that have been whitelisted.
  def self.attributes
    @white_list
  end

  # takes an array of hashes.
  # returns array of objects.
  def self.parse_all(results)
    [].tap do |parsed_results|
      results.each do |result|
        parsed_results << self.new(result)
      end
    end
  end

  # takes a hash of { attr_name => attr_val }.
  # checks the whitelist.
  # if the key (attr_name) is in the whitelist, the value (attr_val)
  # is assigned to the instance variable.
  def initialize(params = {})
    params.each do |var_name, var_value|
      unless self.class.attributes.include?(var_name.to_sym)
        raise "Can't multi assign #{var_name}, not accessible."
      end

      self.instance_variable_set("@#{var_name}", var_value)
    end
  end
end
