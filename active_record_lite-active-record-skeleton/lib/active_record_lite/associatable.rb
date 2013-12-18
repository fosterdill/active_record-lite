require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_accessor :primary_key, :foreign_key, :name
  def other_class
    @class_name.constantize
  end

  def other_table
    other_table = @class_name.gsub(/[A-Z]/) do |capital_letter|
      '_' + capital_letter.downcase
    end[1..-1]

    other_table += (other_table[-1] == 's' ? '' : 's')
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params = {})
    @name = name.to_s
    @class_name = params[:class_name] || 
      name.to_s.split('_').map(&:capitalize).join('')
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || @name + '_id'
  end

  def type
    :belongs_to
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @name = name.to_s
    @class_name = params[:class_name] || 
      name.to_s.split('_').map(&:capitalize).join('')
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || @name + '_id'

    @class_name = (@class_name[-1] == 's' ? @class_name[0..-2] : @class_name)
  end

  def type
    :has_many
  end
end

module Associatable
  @assoc_params = []

  def self.assoc_params
    @assoc_params
  end

  def belongs_to(name, params = {})
    @assoc_params[name] = HasManyAssocParams.new(name, params, self.class.to_s)
    other_table = @assoc_params[name].other_table
    foreign_key = @assoc_params[name].foreign_key
    primary_key = @assoc_params[name].primary_key

    define_method(name) do
      records = DBConnection.execute(<<-SQL)
        SELECT
          #{other_table}.*
        FROM
          #{other_table}
        JOIN
          #{self.class.table_name} 
          ON 
          #{other_table}.#{primary_key} = 
          #{self.class.table_name}.#{foreign_key}
        WHERE 
          #{self.class.table_name}.#{primary_key} = #{self.id}
      SQL

      records.map do |row| 
        @assoc_params[name].other_class.new(row) 
      end.first
    end
  end

  def has_many(name, params = {})
    @assoc_params[name] = HasManyAssocParams.new(name, params, self.class.to_s)
    other_table = @assoc_params[name].other_table
    foreign_key = @assoc_params[name].foreign_key
    primary_key = @assoc_params[name].primary_key

    define_method(name) do
      records = DBConnection.execute(<<-SQL)
        SELECT
          #{other_table}.*
        FROM
          #{other_table}
        JOIN
          #{self.class.table_name} 
          ON 
          #{self.class.table_name}.#{primary_key} = 
          #{other_table}.#{foreign_key}
        WHERE 
          #{self.class.table_name}.#{primary_key} = #{self.id}
      SQL

      records.map do |row| 
        @assoc_params[name].other_class.new(row) 
      end
    end
 
  end

  def has_one_through(name, assoc1, assoc2)
    p @assoc_params
  end
end
