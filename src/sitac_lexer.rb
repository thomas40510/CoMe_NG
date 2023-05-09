# frozen_string_literal: true

require_relative 'token'
require_relative 'sem_ntk'

# Lexer module for Melissa Converter NG
# @author PRV
# @note This module contains the lexer and its subclasses
# @version 1.0.0
# @date 2023
module SITACLexer
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
end

# XML lexer from given set of syntax
# @author PRV
# @note This lexer is auto-generated from a xml file, extracting its keywords
class XMLLexer
  include SITACLexer
  def initialize(file, syntax = 'ntk')
    @rules = []
    @semset = syntax == 'ntk' ? NTKSemantics.new.regexes : nil
    Log.info('Creating lexer', 'CoMe_Lexer')
    @code = File.read(file)
    @code = @code.to_s.gsub(/\s{2,}/, "\n")
    gen_lexer
    @tokens = []
    Log.info('Lexer created', 'CoMe_Lexer')
  end

  def token tk
    token = tk.keys.first
    pattern = tk.values.first
    @rules << [token, pattern]
  end

  def gen_lexer
    # syntax file to tokens
    @semset.each do |key, value|
      token ":#{key}" => value
    end
  rescue StandardError
    Log.err('Error while generating lexer', 'CoMe_Lexer')
  end

  def get_tokens
    # get matches for rules
    @rules.each do |rule, regex|
      # for each match, create a token
      Log.debug("Matching rule #{rule} with regex #{regex}", 'CoMe_Lexer', "\r")
      val = []
      # @code.scan(regex).each do |match|
      #   val << match.first
      # end
      @tokens << Token.new(rule, @code.scan(regex), 0)

      # val = @code.scan(regex)[-1].to_s.gsub('\\r\\n', '').gsub(/\s{2,}/, '')
      # line = @code.lines.index(val)
      # @tokens << Token.new(rule, val, line) if val
      Log.info("Read #{@tokens.length} lexems from #{@code.length} bytes of code.", 'CoMe_Lexer', "\r")
    end
    @tokens
  end

  def tokenize
    Log.info('Tokenizing', 'CoMe_Lexer')
    get_tokens
    Log.info("Tokenized #{@tokens.length} tokens", 'CoMe_Lexer')
    @tokens
  end
end

# test on file
if __FILE__ == $PROGRAM_NAME
  filename = 'input/test.xml'
  lexer = XMLLexer.new(filename)
  tokens = lexer.tokenize
end

