# frozen_string_literal: true

# Logging module for Melissa Converter NG
# @author PRV
# @note This module is used to log messages in the console
# @version 1.0.0
# @date 2023
module LogUtils
  Log = Object.new

  # Log an error message
  # @param message [String] the message to log
  # @param tag [String] the tag to display
  # @return [void]
  def Log.err(message = 'Error', tag = '')
    printf "\e[31m[Log/E] #{tag} : #{message}\e[0m\n"
  end

  # Log a debug message
  # @param message [String] the message to log
  # @param tag [String] the tag to display
  # @param after [String] the string to append after the message
  # @return [void]
  def Log.debug(message = 'Info', tag = '', after = "\n")
    printf "\e[34m[Log/D] #{tag} : #{message}\e[0m#{after}"
  end

  # Log an info message
  # @param message [String] the message to log
  # @param tag [String] the tag to display
  # @param after [String] the string to append after the message
  # @return [void]
  def Log.info(message = 'Debug', tag = '', after = "\n")
    printf "[Log/I] #{tag} : #{message}#{after}"
  end

  # Log a success message
  # @param message [String] the message to log
  # @param tag [String] the tag to display
  # @param after [String] the string to append after the message
  # @return [void]
  def Log.succ(message = 'Success', tag = '', after = "\n")
    printf "\e[32m[Log/S] #{tag} : #{message}\e[0m#{after}"
  end
end

