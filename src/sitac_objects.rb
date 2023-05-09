# frozen_string_literal: true

# Representation of SITAC objects
#
# This file contains the classes representing SITAC objects, with their main attributes.
# @note No logic is implemented in this module, only the representation of the objects.
# @author PRV
# @version 1.0.0
# @date 2023

# utility function
module SITACObjects
  def as_point(point)
    if point.instance_of?(Point)
      point
    else
      Point.new('', point[0], point[1])
    end
  end
end

# Represents a point
class Point
  attr_reader :name, :latitude, :longitude

  # @param name [String] the name of the point
  # @param latitude [Float] the latitude of the point
  # @param longitude [Float] the longitude of the point
  def initialize(name, latitude, longitude)
    @name = name
    @latitude = latitude
    @longitude = longitude
  end
end

# Represents a line, given a list of points
class Line
  attr_reader :name, :points

  # @param name [String] the name of the line
  # @param points [Array<Point>, Array<Array>] the list of points of the line
  def initialize(name, points)
    @name = name
    @points = []
    points.each do |point|
      @points << as_point(point)
    end
  end
end

# Represents a polygon, given a list of points
class Polygon < Line
  # @param name [String] the name of the polygon
  # @param points [Array<Point>, Array<Array>] the list of points of the polygon
end

# Represents a rectangle, given a starting point, a horizontal length and a vertical length
class Rectangle
  attr_reader :name, :start, :horizontal, :vertical

  # @param name [String] the name of the rectangle
  # @param start [Point, Array] the starting point of the rectangle
  # @param horizontal [Float] the horizontal length of the rectangle
  # @param vertical [Float] the vertical length of the rectangle
  def initialize(name, start, horizontal, vertical)
    @name = name
    @start = start
    @horizontal = horizontal
    @vertical = vertical
  end
end

# Represents a bull's eye, given its characteristics (center, radii, nbr of rings, distance between rings)
# @see: https://server.3rd-wing.net/public/Galevsky/Utilisation%20Bullseye.pdf
class Bullseye
  attr_reader :name, :center, :hradius, :vradius, :rings, :ring_distance

  # @param name [String] the name of the bull's eye
  # @param center [Point, Array] the center of the bull's eye
  # @param hradius [Float] the horizontal radius of the bull's eye
  # @param vradius [Float] the vertical radius of the bull's eye
  # @param rings [Integer] the number of rings of the bull's eye
  # @param ring_distance [Float] the distance between rings of the bull's eye
  def initialize(name, center, hradius, vradius, rings, ring_distance)
    @name = name
    @center = as_point(center)
    @hradius = hradius
    @vradius = vradius
    @rings = rings
    @ring_distance = ring_distance
  end
end

# Represents a ellipse, given its center and radii
class Ellipse
  attr_reader :name, :center, :hradius, :vradius

  # @param name [String] the name of the ellipse
  # @param center [Point, Array] the center of the ellipse
  # @param hradius [Float] the horizontal radius of the ellipse
  # @param vradius [Float] the vertical radius of the ellipse
  def initialize(name, center, hradius, vradius)
    @name = name
    @center = as_point(center)
    @hradius = hradius
    @vradius = vradius
  end
end

# Represents a corridor, given its starting point, its ending point and its width
class Corridor
  attr_reader :name, :start_point, :end_point, :width

  # @param name [String] the name of the corridor
  # @param startpt [Point, Array] the starting point of the corridor
  # @param endpt [Point, Array] the ending point of the corridor
  # @param width [Float] the width of the corridor
  def initialize(name, startpt, endpt, width)
    @name = name
    @start_point = as_point(startpt)
    @end_point = as_point(endpt)
    @width = width
  end
end

# register the SITACObjects module for all classes
Object.include SITACObjects
