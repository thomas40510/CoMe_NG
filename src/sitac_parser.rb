# frozen_string_literal: true

require_relative 'sitac_lexer'
require_relative 'sem_ntk'
require_relative 'sitac_objects'
require_relative 'log_utils'

# Parser for Melissa Converter NG
# @note This module contains the parser and its subclasses
# @author PRV
# @version 1.0.0
# @date 2023
module SITACParser
  include LogUtils
  # Parsing exception class
  class ParsingException < StandardError
    @message = 'Error while parsing SITAC file'
  end
end

# Parser for SITAC files
# @note This class is used to parse a SITAC file and identify its objects
# @author PRV
# @version 1.0.0
# @date 2023
class NorthropParser
  include SITACParser
  attr_reader :figures, :tokens, :name

  def initialize(tokens)
    @tokens = tokens
    @name = @tokens.find { |token| token.type == ':figName' }.value.first.first
    @figures = []
    @sems, @regexes = NTKSemantics.new.sems_and_regexes
  end

  def parse_figures
    Log.info('Parsing figures', 'CoMe_Parser')
    @tokens.each do |token|
      next unless token.is_a? ':figure'

      token.value.each do |fig|
        @figures << parse_figure(fig.first)
      end
    end
    Log.info("Done! #{@figures.length} figures parsed", 'CoMe_Parser')
    @figures
  end

  def parse_figure(token)
    type = token.match(@regexes[:figType])[1].downcase
    name = token.match(@regexes[:figName])[1]
    printf "Parsing figure #{name} of type #{type}\r"
    val = send("parse_#{type}", token, name)
    val unless val.nil?
  rescue StandardError => e
    Log.err("Error while parsing figure, I'm ignoring it (#{e})", 'CoMe_Parser')
  end

  def radii(token)
    horiz = token.match(@regexes[:figHoriz])[1].to_f
    vert = token.match(@regexes[:figVert])[1].to_f
    [horiz, vert]
  end

  def parse_point(token, name = 'Pt')
    latitude = token.match(@regexes[:ptLatitude])[1].to_f
    longitude = token.match(@regexes[:ptLongitude])[1].to_f
    Point.new(name, latitude, longitude)
  end

  def parse_line(token, name = 'Ln')
    points = token.scan(@regexes[:figPoint])
    coords = []
    points.each do |point|
      coords << parse_point(point.first)
    end
    Line.new(name, coords)
  end

  def parse_bullseye(token, name = 'Bs')
    # [type, name, latitude, longitude, horiz, vert, nbr_of_rings, distance_between_rings]
    pos = parse_point(token.scan(@regexes[:figPoint]).first.first, '')
    horiz, vert = radii(token)
    rings = token.match(@regexes[:bullsRings])[1].to_i
    dist = token.match(@regexes[:bullsDist])[1].to_f
    Bullseye.new(name, pos, horiz, vert, rings, dist)
  end

  def parse_ellipse(token, name = 'El')
    pos = parse_point(token.scan(@regexes[:figPoint]).first.first, '')
    horiz, vert = radii(token)
    Ellipse.new(name, pos, horiz, vert)
  end

  def parse_rectangle(token, name = 'Rt')
    pos = parse_point(token.scan(@regexes[:figPoint]).first.first, '')
    horiz, vert = radii(token)
    Rectangle.new(name, pos, horiz, vert)
  end

  def parse_corridor(token, name = 'Cr')
    points = token.scan(@regexes[:figPoint])
    coords = []
    points.each do |point|
      coords << parse_point(point.first)
    end
    startpt = coords[0]
    endpt = coords[1]
    width = token.match(@regexes[:figHoriz])[1].to_f
    Corridor.new(name, startpt, endpt, width)
  end

rescue StandardError => e
  Log.error("Error while processing: #{e.message}", 'CoMe_Parser')

end

if __FILE__ == $PROGRAM_NAME
  lexer = XMLLexer.new('input/test.xml')
  tokens = lexer.tokenize
  parser = NorthropParser.new(tokens)
  figures = parser.parse_figures
  puts figures
end
