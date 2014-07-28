require "thread"
require "optparse"
require "logger"
require "fileutils"
require "timeout"

require "daemonic/version"
require "daemonic/daemon"
require "daemonic/cli"
require "daemonic/producer"
require "daemonic/pool"

Thread.abort_on_exception = true

module Daemonic

  def self.run(default_options = {}, &worker_proc)
    command, options = CLI.new(ARGV, default_options).run
    case command
    when :start   then start(options, &worker_proc)
    when :stop    then stop(options)
    when :status  then status(options)
    when :restart then restart(options, &worker_proc)
    end
  end

  def self.start(options, &worker_proc)
    daemon = Daemon.new(options)
    daemon.start do
      worker = worker_proc.call
      Producer.new(worker, options).run
    end
  end

  def self.stop(options)
    Daemon.new(options).stop
  end

  def self.status(options)
    Daemon.new(options).status
  end

  def self.restart(options, &worker_proc)
    daemon = Daemon.new(options.merge(daemonize: true))
    daemon.restart do
      worker = worker_proc.call
      Producer.new(worker, options).run
    end
  end

end
