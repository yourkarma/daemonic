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

  def self.run(worker, default_options = {})
    command, options = CLI.new(ARGV, default_options).run
    case command
    when :start   then start(worker, options)
    when :stop    then stop(options)
    when :status  then status(options)
    when :restart then restart(worker, options)
    end
  end

  def self.start(worker, options)
    daemon = Daemon.new(options)
    daemon.start do
      Producer.new(worker, options).run
    end
  end

  def self.stop(options)
    Daemon.new(options).stop
  end

  def self.status(options)
    Daemon.new(options).status
  end

  def self.restart(worker, options)
    daemon = Daemon.new(options.merge(daemonize: true))
    daemon.restart do
      Producer.new(worker, options).run
    end
  end

end
