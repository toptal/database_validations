require 'erb'
require 'yaml'

module DatabaseConfig
  def self.load(symbolize_keys: false)
    yaml_path = File.expand_path('database.yml', __dir__)
    yaml_content = ERB.new(File.read(yaml_path)).result
    configs = YAML.safe_load(yaml_content)
    configs = configs.transform_values { |v| v.transform_keys(&:to_sym) } if symbolize_keys
    configs
  end
end
