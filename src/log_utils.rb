# frozen_string_literal: true

# Logging module for Melissa Converter NG
# @author PRV
# @note This module is used to log messages in the console
# @version 1.0.0
# @date 2023
module LogUtils
  Log = Object.new

  def Log.err(message = 'Error', tag = '')
    printf "\e[31m[Log/E] #{tag} : #{message}\e[0m\n"
  end

  def Log.debug(message = 'Info', tag = '', after = "\n")
    printf "\e[34m[Log/D] #{tag} : #{message}\e[0m#{after}"
  end

  def Log.info(message = 'Debug', tag = '', after = "\n")
    printf "[Log/I] #{tag} : #{message}#{after}"
  end

  def Log.succ(message = 'Success', tag = '', after = "\n")
    printf "\e[32m[Log/S] #{tag} : #{message}\e[0m#{after}"
  end
end

