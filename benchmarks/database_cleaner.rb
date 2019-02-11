def clear_database!(configuration)
  ActiveRecord::Base.connection.execute 'SET FOREIGN_KEY_CHECKS=0;' if configuration[:adapter] == 'mysql2'
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table, force: :cascade)
  end
  ActiveRecord::Base.connection.execute 'SET FOREIGN_KEY_CHECKS=1;' if configuration[:adapter] == 'mysql2'
end
