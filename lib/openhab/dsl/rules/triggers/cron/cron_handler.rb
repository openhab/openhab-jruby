# frozen_string_literal: true

require "singleton"

require_relative "cron"

module OpenHAB
  module DSL
    module Rules
      module Triggers
        # @!visibility private
        #
        # Cron trigger handler that provides trigger ID
        #
        module CronHandler
          # Cron Trigger Handler that provides trigger IDs
          # Unfortunatly because the CronTriggerHandler in openHAB core is marked internal
          # the entire thing must be recreated here
          class CronTriggerHandler < org.openhab.core.automation.handler.BaseTriggerModuleHandler
            include org.openhab.core.scheduler.SchedulerRunnable
            include org.openhab.core.automation.handler.TimeBasedTriggerHandler

            # Provides access to protected fields
            field_accessor :callback

            # Creates a new CronTriggerHandler
            # @param [org.openhab.core.automation.Trigger] trigger openHAB trigger associated with handler
            #
            def initialize(trigger)
              @trigger = trigger
              @scheduler = OSGi.service("org.openhab.core.scheduler.CronScheduler")
              @schedule = nil
              @expression = trigger.configuration.get("cronExpression")
              super(trigger)
            end

            #
            # Set the callback to execute when cron trigger fires
            # @param [Object] callback to run
            #
            def setCallback(callback) # rubocop:disable Naming/MethodName
              synchronized do
                super(callback)
                @schedule = @scheduler.schedule(self, @expression)
                logger.trace("Scheduled cron job '#{@expression}' for trigger '#{@trigger.id}'.")
              end
            end

            #
            # Get the temporal adjuster
            # @return [CronAdjuster]
            #
            def getTemporalAdjuster # rubocop:disable Naming/MethodName
              org.openhab.core.scheduler.CronAdjuster.new(@expression)
            end

            #
            # Execute the callback
            #
            def run
              callback&.triggered(@trigger, { "module" => @trigger.id })
            end

            #
            # Displose of the handler
            # cancel the cron scheduled task
            #
            def dispose
              synchronized do
                super
                return unless @schedule

                @schedule.cancel(true)
                @schedule = nil
              end
              logger.trace("cancelled job for trigger '#{@trigger.id}'.")
            end
          end

          # Implements the ScriptedTriggerHandlerFactory interface to create a new Cron Trigger Handler
          class CronTriggerHandlerFactory
            include Singleton
            include org.openhab.core.automation.module.script.rulesupport.shared.factories.ScriptedTriggerHandlerFactory

            def initialize
              Core.automation_manager.add_trigger_handler(
                Cron::CRON_TRIGGER_MODULE_ID,
                self
              )

              Core.automation_manager.add_trigger_type(org.openhab.core.automation.type.TriggerType.new(
                                                         Cron::CRON_TRIGGER_MODULE_ID,
                                                         nil,
                                                         "A specific instant occurs",
                                                         "Triggers when the specified instant occurs",
                                                         nil,
                                                         org.openhab.core.automation.Visibility::VISIBLE,
                                                         nil
                                                       ))
              logger.trace("Added script cron trigger handler")
            end

            # Invoked by openHAB core to get a trigger handler for the supplied trigger
            # @param [org.openhab.core.automation.Trigger] trigger
            #
            # @return [WatchTriggerHandler] trigger handler for supplied trigger
            def get(trigger)
              CronTriggerHandler.new(trigger)
            end
          end
        end
      end
    end
  end
end
