# frozen_string_literal: true

require_relative 'token'
require_relative 'semantics'
require_relative 'log_utils'


# XML lexer from given set of syntax
# @author PRV
# @note This lexer is auto-generated from a xml file, extracting its keywords
class XMLLexer
  include LogUtils
  # Initialize the lexer
  # @param file [String] the file to read the SITAC from
  # @param syntax [String] the syntax to use (ntk/melissa)
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

  # add a token to the rules
  # @param tk [Token] the token to add
  def token tk
    token = tk.keys.first
    pattern = tk.values.first
    @rules << [token, pattern]
  end

  # Generate the lexer from the syntax file
  def gen_lexer
    # syntax file to tokens
    @semset.each do |key, value|
      token ":#{key}" => value
    end
  rescue StandardError
    Log.err('Error while generating lexer', 'CoMe_Lexer')
  end

  # Get the tokens from the code
  def get_tokens
    # get matches for rules
    @rules.each do |rule, regex|
      # for each match, create a token
      @tokens << Token.new(rule, @code.scan(regex), 0)

      Log.info("Read #{@tokens.length} lexems from #{@code.length} bytes of code.", 'CoMe_Lexer', "\r")
    end
    @tokens
  end

  # Tokenize the code
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

