module Daemonic
  class Daemon

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def start(&block)
      fail ArgumentError, "No block given" if block.nil?
      if options[:daemonize]
        ensure_pid_specified
        fork do
          at_exit { cleanup_pid_file }
          Process.daemon(true)
          write_pid_file
          block.call
        end
        sleep 0.1
        wait_until(options.fetch(:startup_timeout) { 1 }) { !running? }
        if running?
          puts "The daemon started successfully"
        else
          puts "The daemon did not start properly"
          exit 1
        end
      else
        at_exit { cleanup_pid_file }
        write_pid_file
        block.call
      end
    end

    def status
      ensure_pid_specified
      if running?
        puts "Running with pid: #{pid.inspect}"
        exit 0
      else
        puts "Not running. Pid: #{pid.inspect}"
        exit 2
      end
    end

    def stop
      ensure_pid_specified
      puts "Stopping"
      if running?
        Process.kill("TERM", pid)
        wait_until(options.fetch(:stop_timeout) { 5 }) { !running? }
        if running?
          puts "Couldn't shut down. Pid: #{pid}"
          exit 1
        else
          puts "Worker shut down."
        end
      else
        puts "Not running. Pid: #{pid.inspect}"
        exit 1
      end
    end

    def restart(&block)
      ensure_pid_specified
      if running?
        stop
        start(&block)
      else
        puts "Not running. Starting a new worker."
        cleanup_pid_file
        start(&block)
      end
    end

    private

    def running?
      return false unless pid
      Process.getpgid(pid)
      true
    rescue Errno::ESRCH
      false
    end

    def pid
      File.exist?(pid_file) && Integer(File.read(pid_file).strip)
    end

    def cleanup_pid_file
      File.unlink(pid_file) if pid_file
    end

    def write_pid_file
      if pid_file
        FileUtils.mkdir_p(File.dirname(pid_file))
        File.open(pid_file, "w") { |f| f.puts Process.pid }
      end
    end

    def pid_file
      options[:pid]
    end

    def wait_until(timeout, &condition)
      sleep 0.1
      Timeout.timeout(timeout) do
        until condition.call
          print "."
          sleep 0.1
        end
      end
      print "\n"
    rescue Timeout::Error
      print "\n"
    end

    def ensure_pid_specified
      unless pid_file
        puts "No location of PID specified."
        exit 1
      end
    end

  end
end
