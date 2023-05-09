# frozen_string_literal: true

require_relative 'token'
require_relative 'sem_ntk'

# Lexer module for Melissa Converter NG
# @author PRV
# @note This module contains the lexer and its subclasses
# @version 1.0.0
# @date 2023
module SITACLexer
  # XML lexer from given set of syntax
  # @author PRV
  # @note This lexer is auto-generated from a xml file, extracting its keywords
  class XMLLexer
    def initialize(file, syntax = 'ntk')
      @rules = []
      @semset = syntax == 'ntk' ? NTKSemantics.new.regexes : nil
      puts '=== Creating Lexer ==='
      @code = File.read(file)
      @code = @code.to_s.gsub(/\s{2,}/, "\n")
      gen_lexer
      @tokens = []
      printf '=== done creating lexer ==='
    end

    def token tk
      token = tk.keys.first
      pattern = tk.values.first
      @rules << [token, pattern]
    end

    def gen_lexer
      # syntax file to tokens
      @semset.each do |key, value|
        printf "Adding token #{key} => #{value}\r"
        token ":#{key}" => value
      end
    rescue StandardError
      puts 'Error while creating lexer'
    end

    def get_tokens
      # get matches for rules
      @rules.each do |rule, regex|
        # for each match, create a token
        puts "Getting tokens for #{rule} => #{regex}"
        puts "matches: #{@code.scan(regex)}"
        val = []
        # @code.scan(regex).each do |match|
        #   val << match.first
        # end
        @tokens << Token.new(rule, @code.scan(regex), 0)

        # val = @code.scan(regex)[-1].to_s.gsub('\\r\\n', '').gsub(/\s{2,}/, '')
        # line = @code.lines.index(val)
        # @tokens << Token.new(rule, val, line) if val
        printf "Read #{@tokens.length} lexems from #{@code.length} bytes of code.\r"
      end
      @tokens
    end

    def tokenize
      puts "\n=== tokenizing ==="
      get_tokens
      puts "\n=== done tokenizing ==="
      @tokens
    end
  end

  # test on file
  if __FILE__ == $PROGRAM_NAME
    filename = 'input/test.xml'
    lexer = XMLLexer.new(filename)
    tokens = lexer.tokenize
    puts tokens
  end
end
