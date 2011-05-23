# encoding: utf-8
module Guard
  class Minitest
    class Runner

      class << self

        def run(paths = [], options = {})
          Runner.new(options).run(paths, options)
        end

      end

      def initialize(options = {})
        minitest_version = begin
          MiniTest::Unit.const_defined?(:VERSION) && MiniTest::Unit::VERSION =~ /^1/ ? 1 : 2
        rescue
          2
        end

        @options = {
          :verbose  => false,
          :notify   => true,
          :bundler  => File.exist?("#{Dir.pwd}/Gemfile"),
          :rubygems => false,
          :version  => minitest_version
        }.merge(options)
      end

      def run(paths, options = {})
        message = options[:message] || "Running: #{paths.join(' ')}"
        UI.info message, :reset => true
        system(minitest_command(paths))
      end

      def seed
        @options[:seed]
      end

      def verbose?
        @options[:verbose]
      end

      def notify?
        @options[:notify]
      end

      def bundler?
        @options[:bundler]
      end

      def rubygems?
        !bundler? && @options[:rubygems]
      end

      def version
        @options[:version].to_i
      end

      private

      def minitest_command(paths)
        cmd_parts = []
        cmd_parts << "bundle exec" if bundler?
        cmd_parts << 'ruby -Itest -Ispec'
        cmd_parts << '-r rubygems' if rubygems?
        cmd_parts << '-r bundler/setup' if bundler?
        paths.each do |path|
          cmd_parts << "-r #{path}"
        end
        if version == 1
          cmd_parts << "-r #{File.expand_path('../runners/version_1_runner.rb', __FILE__)}"
        else
          cmd_parts << "-r #{File.expand_path('../runners/version_2_runner.rb', __FILE__)}"
        end
        if notify?
          cmd_parts << '-e \'GUARD_NOTIFY=true; MiniTest::Unit.autorun\''
        else
          cmd_parts << '-e \'GUARD_NOTIFY=false; MiniTest::Unit.autorun\''
        end
        cmd_parts << '--'
        cmd_parts << "--seed #{seed}" unless seed.nil?
        cmd_parts << '--verbose' if verbose?
        cmd_parts.join(' ')
      end

    end
  end
end

