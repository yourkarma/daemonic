# Stolen from RubyTapas by Avdi Grimm, episode 145.
module Daemonic
  class Pool

    class StopSignal

      def inspect
        "[STOP SIGNAL]"
      end
      alias_method :to_s, :inspect

    end

    STOP_SIGNAL = StopSignal.new

    attr_reader :producer

    def initialize(producer)
      @producer = producer
      @jobs    = SizedQueue.new(producer.queue_size)
      @threads = producer.concurrency.times.map {|worker_num|
        Thread.new do
          dispatch(worker_num)
        end
      }
    end

    def enqueue(job)
      logger.debug { "Enqueueing #{job.inspect}" }
      @jobs.push(job)
    end
    alias_method :<<, :enqueue

    def stop
      @threads.size.times do
        enqueue(STOP_SIGNAL)
      end
      @threads.each(&:join)
    end

    private

    def dispatch(worker_num)
      logger.debug { "T#{worker_num}: Starting" }
      loop do
        job = @jobs.pop
        if STOP_SIGNAL.equal?(job)
          logger.debug { "T#{worker_num}: Received stop signal, terminating." }
          break
        end
        begin
          logger.debug { "T#{worker_num}: Consuming #{job.inspect}" }
          worker.consume(job)
          Thread.pass
        rescue Object => error
          if error.is_a?(SystemExit) # allow app to exit
            logger.warn { "T#{worker_num}: Received SystemExit, shutting down" }
            producer.stop
          else
            logger.warn { "T#{worker_num}: #{error.class} while processing #{job}: #{error}" }
            logger.info { error.backtrace.join("\n") }
          end
          Thread.pass
        end
      end
      logger.debug { "T#{worker_num}: Stopped" }
    end

    def worker
      producer.worker
    end

    def logger
      producer.logger
    end

  end
end
