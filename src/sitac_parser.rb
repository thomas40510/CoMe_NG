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
          @figures << parse_figure(fig.first)
        end
      end
      puts '=== done parsing figures ==='
      @figures
    end

    def parse_figure(token)
      type = token.match(@regexes[:figType])[1].downcase
      name = token.match(@regexes[:figName])[1]
      puts "Parsing figure #{name} of type #{type}"
      val = send("parse_#{type}", token, name)
      puts "Parsed figure #{name} of type #{type} with value #{val}"
      val unless val.nil?
    rescue StandardError => e
      puts "Error while parsing figure: #{e}"
    end

    def parse_point(token, name)
      latitude = token.match(@regexes[:ptLatitude])[1].to_f
      longitude = token.match(@regexes[:ptLongitude])[1].to_f
      puts "Parsed point #{name} at #{latitude}, #{longitude}"
      ['point', name, latitude, longitude]
    end

    def radii(token)
      horiz = token.match(@regexes[:figHoriz])[1].to_f
      vert = token.match(@regexes[:figVert])[1].to_f
      [horiz, vert]
    end

    def parse_line(token, name)
      points = token.scan(@regexes[:figPoint])
      puts "Points: #{points}"
      coords = []
      puts "found #{points.length} points"
      points.each do |point|
        puts "Parsing point #{point}"
        coords << parse_point(point.first, '')[2..3]
        puts "Coords: #{coords}"
      end
      ['line', name, coords]
    end

    def parse_bullseye(token, name)
      # [type, name, latitude, longitude, horiz, vert, nbr_of_rings, distance_between_rings]
      pos = token.scan(@regexes[:figPoint]).first.first
      pos = parse_point(pos, '')[2..3]
      horiz, vert = radii(token)
      rings = token.match(@regexes[:bullsRings])[1].to_i
      dist = token.match(@regexes[:bullsDist])[1].to_f
      ['bullseye', name, pos[0], pos[1], horiz, vert, rings, dist]
    end

    def parse_ellipse(token, name)
      ['ellipse', name]
    end

    def parse_rectangle(token, name)
      ['rectangle', name]
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
