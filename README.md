# Daemonic

Daemonic makes multi-threaded daemons easy. All you need to do is provide the
code that actually does the thing you need to do and you're done.

Because Daemonic is designed to perform multi-threaded work, you need to
organize your code to fit a "provider-consumer" pattern.

Your worker needs to be an object that responds to the `produce` and `consume`
methods. Behind the scenes, Daemonic creates a thread pool and delegate work to
each of the threads.

## Example

Let's build a daemon that downloads and parses RSS feeds parses them. You can
find this example in the examples directory of the project.

``` ruby
#!/usr/bin/env ruby

require "nokogiri"
require "open-uri"
require "daemonic"

class FeedWorker

  # some feeds as an example
  URLS = %w(
    https://blog.yourkarma.com/rss
    http://gigaom.com/feed
  ) * 5

  # The produce method determines what to work on next.
  # Put the work onto the queue that is passed in.
  def produce(queue)
    URLS.each do |url|
      queue << url
    end
  end

  # The consume method does the actual hard work of downloading the feed and parsing it.
  def consume(message)
    puts "Downloading #{message}"
    items = Nokogiri::XML(open(message)).css("item")
    puts "Processing #{items.size} articles from #{message}"
  end

end

Daemonic.run { FeedWorker.new }
```

Make the file executable:

```
$ chmod u+x rss
```

Then start the daemon:

```
$ ./rss start --concurrency 10 --daemonize --pid tmp/worker.pid
```

And you can stop it:

```
$ ./rss stop --pid tmp/worker.pid
```

Stopping might take a while, because it gently shuts down all the threads,
letting them finish their work first.

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'daemonic'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install daemonic
```

## Usage

When you get down to it, you only need to do these things to create a
multi-threaded daemon:

* Create an executable.
* Require daemonic.
* Require your own worker.
* End the executable with `Daemonic.run { my_worker }`.

You can get help, by running the script you created:

```
$ ./my_worker
```

And get help for each command, by passing `--help` to the command:

```
$ ./my_worker start --help
```

## How does it work?

When starting a
[SizedQueue](http://ruby-doc.org/stdlib-2.0.0/libdoc/thread/rdoc/SizedQueue.html
) will be created. A bunch of threads (specified by the `--concurrency` option)
will be spawned to listen to that queue. Each message they pick up will be sent
to the worker object you provided to be consumed.

A separate thread will be started that calls your `produce` method continuously.
Because the SizedQueue has a limit, it will block when the queue is full, until
some of the consumers are done.

This approach works great for queueing systems. The produce method finds the
next item, the consume method does the actual work.

## Gotchas

Because Daemonic is multi-threaded, your code needs to be thread-safe.

Also, MRI has a Global Interpreter Lock (GIL). This means that under MRI you
cannot do proper multithreading. This might be a problem for you if most of
the work you are trying to do is CPU bound. If most work is IO bound (like
downloading stuff from the internet), this shouldn't be a problem. When one
consumer is busy doing IO, the other consumers can run. Therefore Daemonic works
great when your daemon is doing mostly IO.

Daemonic ignores all errors. This means that Daemonic will keep on running, but
you need to make sure you still get notified of those errors.

When using the restart command, you need to provide all the options you provide
as if starting the application. Restarting only makes sense for daemonized
processes.

## Contributing

1. Fork it ( https://github.com/yourkarma/daemonic/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
