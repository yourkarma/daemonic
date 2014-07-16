module Daemonic
  class Producer

    attr_reader :worker, :concurrency, :options, :queue_size

    def initialize(worker, options)
      @worker      = worker
      @options     = options
      @concurrency = options.fetch(:concurrency) { 4 }
      @queue_size  = options.fetch(:queue_size) { @concurrency + 1 }
      @logger      = options[:logger]
      @running     = true
    end

    def run
      logger.info "Starting producer with #{concurrency} consumer threads."

      Signal.trap("INT") { stop }
      Signal.trap("TERM") { stop }

      pool = Pool.new(self)

      producer = Thread.new do
        while @running
          worker.produce(pool)
          Thread.pass
        end
        logger.info { "Producer has been shut down. Stopping the thread pool" }
        pool.stop
      end

      producer.join

      logger.info { "Shutting down" }

    end

    def stop
      @running = false
    end

    def logger
      @logger ||= Logger.new(@options[:log] || STDOUT).tap { |logger|
        logger.level = @options[:log_level] || Logger::INFO
      }
    end

  end
end
