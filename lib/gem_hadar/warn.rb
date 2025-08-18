require 'term/ansicolor'

class GemHadar
  # A module that provides warning functionality with colored output.
  #
  # This module enhances the standard warn method to display warning messages
  # in orange color, making them more visible in terminal outputs. It is
  # designed to be included in classes that need consistent warning message
  # formatting throughout the application.
  #
  # @example Using the warn method from this module
  #   class MyClass
  #     include GemHadar::SimpleCov::Warn
  #
  #     def my_method
  #       warn "This is a warning message"
  #     end
  #   end
  module Warn
    include Term::ANSIColor
    # The warn method displays warning messages using orange colored output.
    #
    # This method takes an array of message strings, applies orange color
    # formatting to each message, and then passes them to the superclass's warn
    # method for display. The uplevel: 1 option ensures that the warning
    # originates from the caller's context rather than from within this method
    # itself.
    #
    # @param msgs [ Array<String> ] the array of message strings to display as warnings
    def warn(*msgs)
      msgs.map! do |a|
        a.respond_to?(:to_str) ? color(208) { a.to_str } : a
      end
      super(*msgs, uplevel: 1)
    end

    # The fail method formats and displays failure messages using red colored output.
    #
    # This method takes an array of message objects, applies red color formatting
    # to string representations of the messages, and then passes them to the
    # superclass's fail method for display. The uplevel: 1 option ensures that
    # the failure message originates from the caller's context rather than from
    # within this method itself.
    #
    # @param msgs [ Array<Object> ] the array of message objects to display as failures
    #
    # @return [ void ]
    def fail(*msgs)
      msgs.map! do |a|
        a.respond_to?(:to_str) ? color(196) { a.to_str } : a
      end
      super(*msgs)
    end
  end
end
