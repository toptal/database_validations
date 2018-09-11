namespace :database_validations do
  task :skip_db_uniqueness_validator_index_check do
    ENV['SKIP_DB_UNIQUENESS_VALIDATOR_INDEX_CHECK'] = 'true'
  end
end
