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

    def initialize(thread_count, worker, logger)
      @worker  = worker
      @jobs    = SizedQueue.new(thread_count)
      @logger  = logger
      @threads = thread_count.times.map {|worker_num|
        Thread.new do
          dispatch(worker_num)
        end
      }
    end

    def enqueue(job)
      @logger.debug { "Enqueueing #{job.inspect}" }
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
      @logger.debug { "T#{worker_num}: Starting" }
      loop do
        job = @jobs.pop
        if STOP_SIGNAL.equal?(job)
          @logger.debug { "T#{worker_num}: Received stop signal, terminating." }
          break
        end
        begin
          @logger.debug { "T#{worker_num}: Consuming #{job.inspect}" }
          @worker.consume(job)
          Thread.pass
        rescue Object => error
          @logger.warn { "T#{worker_num}: Error while processing #{job}: #{error.class}: #{error}" }
          @logger.info { error.backtrace.join("\n") }
          Thread.pass
        end
      end
      @logger.debug { "T#{worker_num}: Stopped" }
    end


  end
end
