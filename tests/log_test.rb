# frozen_string_literal: true

require 'logging'

require_relative '../src/log_utils'


class LogTest
  include LogUtils
  def initialize
    $logger = Logging.logger['LogTest']
    $logger.level = :debug
    $logger.add_appenders Logging.appenders.stdout

    Log.err('Error', 'Test')
    Log.debug('Debug', 'Test')
    Log.info('Info', 'Test')
    Log.succ('Success', 'Test')
  end
end

LogTest.new
