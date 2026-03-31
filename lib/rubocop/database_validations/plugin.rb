require 'lint_roller'

module RuboCop
  module DatabaseValidations
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-database_validations',
          version: ::DatabaseValidations::VERSION,
          homepage: 'https://github.com/toptal/database_validations',
          description: 'RuboCop cops for database_validations gem.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: File.join(__dir__, '..', '..', '..', 'config', 'rubocop-default.yml')
        )
      end
    end
  end
end
