require_relative './db_connection'

module Searchable
  # takes a hash like { :attr_name => :search_val1, :attr_name2 => :search_val2 }
  # map the keys of params to an array of  "#{key} = ?" to go in WHERE clause.
  # Hash#values will be helpful here.
  # returns an array of objects
  def where(params)
    table_name = self.table_name

    where_string = params.keys.map do |attr_name|
      "#{attr_name} = ?"
    end.join(' AND ')

    param_values = params.values.map do |value|
      value.is_a?(String) ? "#{value.to_s}" : value.to_s
    end

    records = DBConnection.execute(<<-SQL, *param_values)
      SELECT
        #{table_name}.*
      FROM 
        #{table_name}
      WHERE
        #{where_string}
    SQL

    records.map { |row| self.new(row) }
  end
end
