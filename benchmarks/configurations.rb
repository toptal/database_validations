require_relative '../config/database_config'

DATABASE_CONFIGURATIONS = DatabaseConfig.load(symbolize_keys: true)

def postgresql_configuration
  DATABASE_CONFIGURATIONS['postgresql']
end

def mysql_configuration
  DATABASE_CONFIGURATIONS['mysql']
end

def sqlite_configuration
  DATABASE_CONFIGURATIONS['sqlite']
end
