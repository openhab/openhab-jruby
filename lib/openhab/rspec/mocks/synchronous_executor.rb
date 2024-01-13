# frozen_string_literal: true

require "singleton"

module OpenHAB
  module RSpec
    module Mocks
      class CallbacksMap < java.util.HashMap
        def put(_rule_uid, trigger_handler)
          if trigger_handler.executor
            trigger_handler.executor.shutdown_now
            trigger_handler.executor = SynchronousExecutor.instance
          end
          super
        end
      end

      class SynchronousExecutor < java.util.concurrent.ScheduledThreadPoolExecutor
        include Singleton

        attr_accessor :main_thread

        def initialize
          # Allocate a (hopefully) big enough pool size to accommodate scheduled tasks
          super(10)
        end

        def submit(runnable)
          return super unless Thread.current == main_thread

          runnable.respond_to?(:run) ? runnable.run : runnable.call

          java.util.concurrent.CompletableFuture.completed_future(nil)
        end

        def execute(runnable)
          return super unless Thread.current == main_thread

          runnable.run
        end

        def shutdown; end

        def shutdown_now
          []
        end
        alias_method :shutdownNow, :shutdown_now
      end

      class SynchronousExecutorMap
        include java.util.Map
        include Singleton

        def get(_key)
          SynchronousExecutor.instance
        end

        def key_set
          java.util.HashSet.new
        end
      end
    end
  end
end
