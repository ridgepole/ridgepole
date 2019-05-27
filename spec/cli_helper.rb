# frozen_string_literal: true

module CLIHelper
  def default_cli_hook
    <<-RUBY.strip_heredoc
      require 'ridgepole'

      class Ridgepole::Delta
        def initialize(*args);
        end
        def migrate(*args)
          puts "Ridgepole::Delta#migrate"
          [#{differ}, "create_table :table do\\nend"]
        end
        def script
          puts "Ridgepole::Delta#script"

          "create_table :table do\\nend"
        end
        def differ?
          puts "Ridgepole::Delta#differ?"
          #{differ}
        end
      end

      class Ridgepole::Client
        def initialize(*args)
          puts "Ridgepole::Client#initialize([\#{args.map {|i| i.kind_of?(File) ? i.path : i.inspect}.join(', ')}])"
        end
        def dump
          puts "Ridgepole::Client#dump"
        end
        def diff(*args)
          puts "Ridgepole::Client#diff"
          Ridgepole::Delta.new
        end
        class << self
          def diff(*args)
            puts "Ridgepole::Client.diff([\#{args.map {|i| i.kind_of?(File) ? i.path : i.inspect}.join(', ')}])"
            Ridgepole::Delta.new
          end
          def dump(args)
            puts "Ridgepole::Client.dump"
          end
        end
      end
    RUBY
  end

  def run_cli(options = {})
    args = options[:args] || []
    hook = options[:hook] || default_cli_hook
    path = File.expand_path('../bin/ridgepole', __dir__)

    Tempfile.open(["#{File.basename __FILE__}.#{$PROCESS_ID}", '.rb']) do |f|
      f.puts(hook)
      f.puts(File.read(path))
      f.flush

      cmd = ([:ruby, f.path] + args).join(' ')
      Open3.capture2e(cmd)
    end
  end
end
include CLIHelper
