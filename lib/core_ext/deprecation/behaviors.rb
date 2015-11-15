module CoreExt
  class DeprecationException < StandardError
  end

  class Deprecation
    # Default warning behaviors per Rails.env.
    DEFAULT_BEHAVIORS = {
      raise: ->(message, callstack) {
        e = DeprecationException.new(message)
        e.set_backtrace(callstack)
        raise e
      },

      stderr: ->(message, callstack) {
        $stderr.puts(message)
        $stderr.puts callstack.join("\n  ") if debug
      },

      log: ->(message, callstack) {
        logger =
            if defined?(Rails.logger) && Rails.logger
              Rails.logger
            else
              require 'active_support/logger'
              CoreExt::Logger.new($stderr)
            end
        logger.warn message
        logger.debug callstack.join("\n  ") if debug
      },

      notify: ->(message, callstack) {
        CoreExt::Notifications.instrument("deprecation.rails",
                                                :message => message, :callstack => callstack)
      },

      silence: ->(message, callstack) {},
    }

    # Behavior module allows to determine how to display deprecation messages.
    # You can create a custom behavior or set any from the +DEFAULT_BEHAVIORS+
    # constant. Available behaviors are:
    #
    # [+raise+]   Raise <tt>CoreExt::DeprecationException</tt>.
    # [+stderr+]  Log all deprecation warnings to +$stderr+.
    # [+log+]     Log all deprecation warnings to +Rails.logger+.
    # [+notify+]  Use +CoreExt::Notifications+ to notify +deprecation.rails+.
    # [+silence+] Do nothing.
    #
    # Setting behaviors only affects deprecations that happen after boot time.
    # For more information you can read the documentation of the +behavior=+ method.
    module Behavior
      # Whether to print a backtrace along with the warning.
      attr_accessor :debug

      # Returns the current behavior or if one isn't set, defaults to +:stderr+.
      def behavior
        @behavior ||= [DEFAULT_BEHAVIORS[:stderr]]
      end

      # Sets the behavior to the specified value. Can be a single value, array,
      # or an object that responds to +call+.
      #
      # Available behaviors:
      #
      # [+raise+]   Raise <tt>CoreExt::DeprecationException</tt>.
      # [+stderr+]  Log all deprecation warnings to +$stderr+.
      # [+log+]     Log all deprecation warnings to +Rails.logger+.
      # [+notify+]  Use +CoreExt::Notifications+ to notify +deprecation.rails+.
      # [+silence+] Do nothing.
      #
      # Setting behaviors only affects deprecations that happen after boot time.
      # Deprecation warnings raised by gems are not affected by this setting
      # because they happen before Rails boots up.
      #
      #   CoreExt::Deprecation.behavior = :stderr
      #   CoreExt::Deprecation.behavior = [:stderr, :log]
      #   CoreExt::Deprecation.behavior = MyCustomHandler
      #   CoreExt::Deprecation.behavior = ->(message, callstack) {
      #     # custom stuff
      #   }
      def behavior=(behavior)
        @behavior = Array(behavior).map { |b| DEFAULT_BEHAVIORS[b] || b }
      end
    end
  end
end