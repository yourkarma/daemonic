Feature: Worker

  Scenario: Starting and stopping

    Given a file named "worker" with mode "744" and with:
      """
      #!/usr/bin/env ruby
      $LOAD_PATH << File.expand_path("../../../lib", __FILE__)
      require "daemonic"

      class MyWorker

        def produce(queue)
          sleep 0.1
          queue << "tick"
        end

        def consume(message)
          puts message
          sleep 0.1
        end

      end

      Daemonic.run { MyWorker.new }
      """

    When I run `./worker start --daemonize --pid tmp/worker.pid`
    Then the exit status should be 0

    When I run `./worker status --pid tmp/worker.pid`
    Then the exit status should be 0

    When I run `./worker restart --pid tmp/worker.pid`
    Then the exit status should be 0

    When I run `./worker stop --pid tmp/worker.pid`
    Then the exit status should be 0

    When I run `./worker status --pid tmp/worker.pid`
    Then the exit status should be 2
