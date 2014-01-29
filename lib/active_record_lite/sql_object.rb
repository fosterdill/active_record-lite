require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  # sets the table_name
  def self.set_table_name(table_name)
    @table_name = table_name
  end

  # gets the table_name
  def self.table_name
    @table_name
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
    records = DBConnection.execute(<<-SQL)
      SELECT
        #{@table_name}.*
      FROM
        #{@table_name}
    SQL

    create_objects_from_array(records)
  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
  def self.find(id)
    records = DBConnection.execute(<<-SQL, id)
      SELECT
        #{@table_name}.*
      FROM
        #{@table_name}
      WHERE
        #{@table_name}.id = ?
    SQL

    create_objects_from_array(records).first
  end

  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection
  def create
    column_names = self.instance_variables.map do |var| 
      var[-1..1] 
    end.join(', ')

    row_values = self.instance_variables.map do |var|
      self.instance_variable_get(var)
    end

    DBConnection.execute(<<-SQL, row_values)
      INSERT INTO
        #{@table_name} #{column_names}
      VALUES
        ?
    SQL

    @id = DBConnection.last_row_id
  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
    attribute_names = self.instance_variables.map { |var| var[1..-1] }

    set_string = attribute_names.map do |var_name|
      "#{var_name} = ?"
    end.join(', ')

    DBConnection.execute(<<-SQL, *self.attribute_values, self.id)
      UPDATE 
        #{self.class.table_name}
      SET
        #{set_string}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end

  # call either create or update depending if id is nil.
  def save
    if(@id.nil?)
      self.create
    else
      self.update
    end
  end

  # helper method to return values of the attributes.
  def attribute_values
    self.instance_variables.map do |var|
      var_value = self.instance_variable_get(var)
      if(var_value.is_a?(String))
        "'#{var_value}'"
      else
        var_value
      end
    end
  end

  private
  def self.create_objects_from_array(array_of_objects)
    array_of_objects.map { |row| self.new(row) }
  end
end
