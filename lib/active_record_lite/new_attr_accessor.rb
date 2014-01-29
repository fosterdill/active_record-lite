class Object
  def self.new_attr_accessor(*var_names)
    var_names.each do |var_name|
      define_method(var_name) do
        instance_variable_get("@#{var_name}")
      end

      define_method("#{var_name}=") do |value|
        instance_variable_set("@#{var_name}", value)
      end
    end
  end
end
