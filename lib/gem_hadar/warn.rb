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
      msgs.map! { |m| color(208) { m } }
      super(*msgs, uplevel: 1)
    end
  end
end
