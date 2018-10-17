# @scope Models
#
# Matches when model validate database uniqueness of some field.
#
# Modifiers:
# * `with_message(message)` -- specifies a message of the error;
# * `scoped_to(scope)` -- specifies a scope for the validator;
# * `with_where(where)` -- specifies a where condition for the validator;
# * `with_index(index_name)` -- specifies an index name for the validator;
#
# Example:
#
# ```ruby
# it { expect(Model).to validate_db_uniqueness_of(:field) }
# ```
RSpec::Matchers.define :validate_db_uniqueness_of do |field|
  chain(:with_message) do |message|
    @message = message
  end

  chain(:scoped_to) do |*scope|
    @scope = scope.flatten
  end

  chain(:with_where) do |where|
    @where = where
  end

  chain(:with_index) do |index_name|
    @index_name = index_name
  end

  match do |model|
    @validators = []

    DatabaseValidations::Helpers.each_validator(model) do |validator|
      @validators << {
        field:      validator.field,
        scope:      validator.scope,
        where:      validator.where_clause,
        message:    validator.message,
        index_name: validator.index_name
      }
    end

    @validators.include?(field: field, scope: Array.wrap(@scope), where: @where, message: @message, index_name: @index_name)
  end

  description do
    desc = "validate database uniqueness of #{field}. "
    desc += "With options - " if @message || @scope || @where
    desc += "message: '#{@message}'; " if @message
    desc += "scope: #{@scope}; " if @scope
    desc += "where: '#{@where}'; " if @where
    desc += "index_name: '#{index_name}'." if @index_name
    desc
  end

  failure_message do
    <<-TEXT
      There is no such database uniqueness validator. 
      Available validators are: #{@validators}.
    TEXT
  end
end
