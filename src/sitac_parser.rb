# frozen_string_literal: true

require_relative 'sitac_lexer'
require_relative 'sem_ntk'

# Parser module for Melissa Converter NG
# @note This module contains the parser and its subclasses
# @author PRV
# @version 1.0.0
# @date 2023
module SITACParser
  # Parsing exception
  class ParsingException < StandardError
    @message = 'Error while parsing SITAC file'
  end

  # Parser for SITAC files
  # @note This class is used to parse a SITAC file and identify its objects
  # @author PRV
  # @version 1.0.0
  # @date 2023
  class NorthropParser
    attr_reader :figures, :tokens

    def initialize(tokens)
      @tokens = tokens
      @figures = []
      @sems, @regexes = NTKSemantics.new.sems_and_regexes
    end

    def parse_figures
      puts '=== Parsing figures ==='
      @tokens.each do |token|
        puts "Current token #{token}"
        next unless token.is_a? ':figure'

        puts "Found figure #{token.value}"
        token.value.each do |fig|
          @figures << parse_figure(fig)
        end
      end
      puts '=== done parsing figures ==='
      @figures
    end

    def parse_figure(token)
      type = token.scan(@regexes[:figType]).first.first.to_s.downcase
      name = token.scan(@regexes[:figName]).first.first.to_s
      puts "Parsing figure #{name} of type #{type}"
      @figures << send("parse_#{type}", token, name)
    rescue StandardError => e
      puts "Error while parsing figure: #{e}"
    end

    def parse_point(token, name)
      latitude = token.scan(@regexes[:ptLatitude]).to_f
      longitude = token.scan(@regexes[:ptLongitude]).to_f
      ['point', name, latitude, longitude]
    end

    def radii(token)
      horiz = token.scan(@regexes[:figHoriz]).to_f
      vert = token.scan(@regexes[:figVert]).to_f
      [horiz, vert]
    end

    def parse_line(token, name)
      points = token.scan(@regexes[:figPoint])
      coords = []
      points.first.each do |point|
        coords << parse_point(point, '')[2..3]
      end
      ['line', name, coords]
    end

    def parse_bullseye(token, name)
      # [type, name, latitude, longitude, horiz, vert, nbr_of_rings, distance_between_rings]
      pos = parse_point(token.scan(@regexes[:figPoint]), '')[2..3]
      horiz, vert = radii(token)
      rings = token.scan(@regexes[:bullsRings]).to_i
      dist = token.scan(@regexes[:bullsDist]).to_f
      ['bullseye', name, pos[0], pos[1], horiz, vert, rings, dist]
    end
  end

  if __FILE__ == $PROGRAM_NAME
    lexer = SITACLexer::XMLLexer.new('input/test.xml')
    tokens = lexer.tokenize
    parser = NorthropParser.new(tokens)
    figures = parser.parse_figures
    puts figures
  end
end
