# frozen_string_literal: true

# Token class for Melissa Converter NG
# @note This class is used to represent a token
# @version 1.0.0
# @author JCLL -- https://github.com/JC-LL
class Token
  attr_accessor :type, :value, :position

  def initialize(type, value, position)
    @type = type
    @value = value
    @position = position
  end

  def is_a? type
    @type == type
  end

  def accept visitor; end

  def self.create str
    Token.new(:id, str, [0, 0])
  end

  def to_s
    "#{@type} : #{@value}"
  end
end

