# frozen_string_literal: true

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum, this matches the default thread size of Active Record.
#
num_workers = ENV.fetch('WEB_CONCURRENCY') { 2 }.to_i
threads_count = ENV.fetch('RAILS_MAX_THREADS') { 16 }.to_i

threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests, default is 3000.
#
port        ENV.fetch('PORT') { 9292 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RAILS_ENV') { 'development' }

if num_workers > 1
  # Specifies the number of `workers` to boot in clustered mode.
  # Workers are forked webserver processes. If using threads and workers together
  # the concurrency of the application would be max `threads` * `workers`.
  # Workers do not work on JRuby or Windows (both of which do not support
  # processes).
  #
  workers num_workers

  # Use the `preload_app!` method when specifying a `workers` number.
  # This directive tells Puma to first boot the application and load code
  # before forking the application. This takes advantage of Copy On Write
  # process behavior so workers use less memory. If you use this option
  # you need to make sure to reconnect any threads in the `on_worker_boot`
  # block.
  #
  bind "tcp://0.0.0.0:#{ENV.fetch('PORT', 9292)}"
  preload_app!

  # Don't wait for workers to finish their work. We might have long-running HTTP requests.
  # But docker gives us only 10 seconds to gracefully handle our shutdown process.
  # This settings tries to shut down all threads after 2 seconds. Puma then gives each thread
  # an additional 5 seconds to finish the work. This adds up to 7 seconds which is still below
  # docker's maximum of 10 seconds.
  # This setting only works on Puma >= 3.4.0.
  force_shutdown_after 2 if respond_to?(:force_shutdown_after)

  # The code in the `on_worker_boot` will be called if you are using
  # clustered mode by specifying a number of `workers`. After each worker
  # process is booted this block will be run, if you are using `preload_app!`
  # option you will want to use this block to reconnect to any threads
  # or connections that may have been created at application boot, Ruby
  # cannot share connections between processes.
  #
  on_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
    if defined?(Resque) && !ENV['NO_RESQUE']
      cfg = Rails.application.config_for(Rails.root + 'config/redis.yml')
      resque_env = "resque:archimedes_#{ENV.fetch('RAILS_ENV').downcase}"
      redis_client = Redis.new(host: cfg['host'], port: cfg['port'])
      Resque.redis = Redis::Namespace.new(resque_env, redis: redis_client)
    end
  end

  # As we are preloading our application and using ActiveRecord
  # it's recommended that we close any connections to the database here to prevent connection leakage
  # This rule also applies to any connections to external services (Redis, databases, memcache, ...)
  # that might be started automatically by the framework.
  before_fork do
    ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
  end
end

custom_config = '/home/app/webapp/config/puma.rb'
instance_eval(File.read(custom_config)) if File.exist?(custom_config)
