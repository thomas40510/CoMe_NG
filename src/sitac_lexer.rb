# frozen_string_literal: true
require 'strscan'
require_relative 'token'

# Lexer module for Melissa Converter NG
# @author PRV
# @note This module contains the lexer and its subclasses
# @version 1.0.0
# @date 2023
module SITAC_Lexer
  # Generic Lexer, capable of accepting any set of custom rules
  # @author JCLL
  # @note This is a generic lexer, it can be used to tokenize any language
  class GenericLexer
    def initialize
      @rules = []
      @rules << [:newline, /\n+/]
      @rules << [:space, /\s+/]
    end

    def open code
      @strscan = StringScanner.new(code)
      @code = code
      @line = 0
    end

    def keyword kw
      # regex to catch the keyword <keyword text...>
      @rules << [kw.to_sym, /<#{kw}\s+>/]
    end

    def token tk
      token = tk.keys.first
      pattern = tk.values.first
      @rules << [token, pattern]
    end

    def next_token
      return nil if @strscan.eos?

      @rules.each do |token, pattern|
        return [token, @strscan.matched] if @strscan.scan(pattern)
      end
      raise 'Unrecognized token'
    end

    def get_token
      pos = position
      @rules.each do |rule, regex|
        value = @strscan.scan(regex)
        return Token.new(rule, value, pos) if value
      end
      Token.new(:unknown, @strscan.getch, pos)
    end

    def position
      if @strscan.pos.zero? || @strscan.pos == @old_pos
        @line += 1
        @old_pos = @strscan.pos
      end
      [@line, @strscan.pos - @old_pos + 1]
    end

    def tokenize(code)
      puts '=== tokenizing ==='
      open(code)
      tokens = []
      until @strscan.eos?
        tokens << get_token
        printf "Read #{tokens.length} tokens from #{code.length} bytes of code.\r"
      end
      puts "\n=== done tokenizing ==="
      tokens
    end
  end

  # XML auto-generated lexer
  # @author PRV
  # @note This lexer is auto-generated from a xml file, extracting its keywords
  class XMLLexer < GenericLexer
    def initialize(file)
      super()
      puts '=== Creating Lexer ==='
      xml = File.read(file)
      # read xml and extract keywords (between < and >)
      keys = []
      xml.scan(%r{<([^/].*?)>}).each do |kw|
        key = kw.first.split(' ').first
        next if keys.include? key

        keys << key
        keyword key
      end
      token closing: %r{</.*?>}
      token ochevron: /</
      token cchevron: />/
      token slash: %r{/}
      token equal: /=/
      token quote: /"/
      token value: /[a-zA-Z0-9_]+/
      printf "Created Lexer with #{keys.length} keywords.\n"
      printf "=== done creating lexer ===\n"
    end
  end

  # test on file
  if __FILE__ == $PROGRAM_NAME
    filename = 'input/test.xml'
    lexer = XMLLexer.new(filename)
    tokens = lexer.tokenize(File.read(filename))
  end
end
