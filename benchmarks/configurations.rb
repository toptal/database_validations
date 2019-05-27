def postgresql_configuration
  {
    adapter: 'postgresql',
    database: 'database_validations_test',
    host: ENV['PGHOST'] || '127.0.0.1'
  }
end

def mysql_configuration
  {
    adapter: 'mysql2',
    database: 'database_validations_test',
    host: ENV['MYSQLHOST'] || '127.0.0.1'
  }
end

def sqlite_configuration
  {
    adapter: 'sqlite3',
    database: ':memory:'
  }
end
