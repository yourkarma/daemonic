module Daemonic
  class CLI

    COMMANDS = %w(start stop status restart help)

    attr_reader :argv, :default_options

    def initialize(argv, default_options = {})
      @argv            = argv
      @default_options = default_options
    end

    def run
      command = argv[0]
      case command
      when nil, "-h", "--help", "help"
        help
        exit
      when "-v", "--version"
        puts "Daemonic version #{Daemonic::VERSION}"
        exit
      when "start"
        start
      when "stop"
        stop
      when "status"
        status
      when "restart"
        restart
      else
        puts "Unknown command #{command.inspect}."
        help
        exit 1
      end
    end

    def help
      info <<-USAGE

        Usage: #{program} COMMAND OPTIONS

        Available commands:
        * start              Start the daemon
        * stop               Stops the daemon
        * restart            Stops and starts a daemonized process
        * status             Shows the status

        To get more information about each command, run the command with --help.

        Example: #{program} start --help

      USAGE
    end

    def start
      options = parse "start", log: STDOUT, concurrency: 2, daemonize: false, startup_timeout: 1
      [ :start, options ]
    end

    def stop
      options = parse "stop", stop_timeout: 5
      [ :stop, options ]
    end

    def status
      options = parse "status"
      [ :status, options ]
    end

    def restart
      options = parse "restart", log: STDOUT, concurrency: 2, stop_timeout: 5, startup_timeout: 1
      [ :restart, options ]
    end

    private

    def program
      $PROGRAM_NAME
    end

    def info(text)
      puts text.gsub(/^ */, '')
    end

    def parse(command, options = {})

      optparser = OptionParser.new { |parser|

        parser.banner = "Usage: #{program} #{command} OPTIONS"

        parser.separator ""
        parser.separator "Process options:"

        parser.on "-P", "--pid LOCATION", "Where the pid file is stored (required for daemonized processes)" do |pid|
          options[:pid] = pid
        end

        if options.has_key?(:daemonize)
          parser.on "-d", "--[no-]daemonize", "Should the process be daemonized" do |daemonize|
            options[:daemonize] = daemonize
          end
        end

        if options.has_key?(:concurrency)
          parser.on "-c", "--concurrency NUMBER", Integer, "How many consumer threads to spawn (default: #{options[:concurrency]})" do |concurrency|
            if concurrency < 1
              puts "Concurrency cannot be smaller than 1."
              exit 1
            end
            options[:concurrency] = concurrency
          end
        end


        if options.has_key?(:startup_timeout)
          parser.on "--startup-timeout TIMEOUT", Integer, "How many seconds to wait for the process to start (default: #{options[:startup_timeout]})" do |timeout|
            if timeout < 1
              puts "Timeout cannot be smaller than 1."
              exit 1
            end
            options[:startup_timeout] = timeout
          end
        end

        if options.has_key?(:stop_timeout)
          parser.on "--stop-timeout TIMEOUT", Integer, "How many seconds to wait for the process to stop (default: #{options[:stop_timeout]})" do |timeout|
            if timeout < 1
              puts "Timeout cannot be smaller than 1."
              exit 1
            end
            options[:stop_timeout] = timeout
          end
        end

        if options.has_key?(:log)

          parser.separator ""
          parser.separator "Logging options:"

          parser.on "--log FILE", "Where to write the log to" do |log|
            options[:log] = log
          end

          parser.on "--verbose", "Sets the log level to debug" do
            options[:log_level] = Logger::DEBUG
          end

          parser.on "--log-level LEVEL", %w(debug info warn fatal), "Set the log level (default: info)" do |level|
            options[:log_level] = Logger.const_get(level.upcase)
          end

        end

        parser.separator ""
        parser.separator "Common options:"

        parser.on_tail("-h", "--help", "Show this message") do
          puts parser
          exit
        end

      }

      begin
        optparser.parse!(argv)
        default_options.merge(options)
      rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => error
        puts error
        puts optparser
        exit 1
      end
    end

  end
end
