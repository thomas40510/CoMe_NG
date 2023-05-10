# frozen_string_literal: true

require_relative 'token'
require_relative 'sem_ntk'
require_relative 'log_utils'


# XML lexer from given set of syntax
# @author PRV
# @note This lexer is auto-generated from a xml file, extracting its keywords
class XMLLexer
  include LogUtils
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

