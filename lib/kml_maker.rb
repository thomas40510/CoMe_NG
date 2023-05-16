# frozen_string_literal: true

require_relative 'sitac_objects'
require_relative 'log_utils'

# Utilities for KML generation
module KMLUtils
  def meters_to_degrees(meters)
    meters / 111_111
  end

  # Create circle around a center
  # @param center [Array] the center of the circle
  # @param radius [Float] the radius of the circle
  # @param nb_points [Integer] the number of points to create the circle
  # @return [Array<Array>] the list of points of the circle
  def create_circle(center, radius, nb_points = 400)
    x, y = center
    points = []
    angle_step = 2 * Math::PI / nb_points
    nb_points.times do |i|
      points << [x + radius * Math.cos(i * angle_step), y + radius * Math.sin(i * angle_step)]
    end
    points
  end

  # Create ellipse around a center, given horizontal and vertical radii
  # @param center [Array] the center of the ellipse
  # @param hradius [Float] the horizontal radius of the ellipse
  # @param vradius [Float] the vertical radius of the ellipse
  # @param angle [Float] the angle of the ellipse
  # @param nb_points [Integer] the number of points to create the ellipse
  # @return [Array<Array>] the list of points of the ellipse
  def create_ellipse(center, hradius, vradius, angle = 0, nb_points = 400)
    x, y = center
    points = []
    angle = angle * Math::PI / 180
    angle_step = 2 * Math::PI / nb_points
    nb_points.times do |i|
      points << [x + hradius * Math.cos(i * angle_step + angle),
                 y + vradius * Math.sin(i * angle_step + angle)]
    end
    points << points[0]
    points
  end

  # create a line apart from a center, given a length and an angle
  # @param center [Array<float>] the center of the line
  # @param length [Float] the length of the line
  # @param angle [Float] the angle of the line
  # @return [Array<Array>] the list of points of the line
  def create_line(center, length, angle = 0)
    points = []
    angle = angle * Math::PI / 180
    points << [center[0] + length * Math.cos(angle), center[1] + length * Math.sin(angle)]
    points << [center[0], center[1]]
    points << [center[0] - length * Math.cos(angle), center[1] - length * Math.sin(angle)]
    points
  end
end

# Generic Visitor class for Melissa Converter NG
# @note This class is generic and not used as is
# @author PRV
# @version 1.0.0
# @date 2023
class Visitor
  include LogUtils
  def initialize
    @content = ''
  end

  # visit a point
  # @param point [Point] the point to visit
  def visit_point(point)
    @content += "Point: #{point.name} (#{point.latitude}, #{point.longitude})\n"
  end

  # visit a line
  # @param line [Line] the line to visit
  def visit_line(line)
    @content += "Line: #{line.name}\n"
    line.points.each do |point|
      visit_point point
    end
    @content += "\n"
  end

  # visit a polygon
  # @param polygon [Polygon] the polygon to visit
  def visit_polygon(polygon)
    @content += "Polygon: #{polygon.name}\n"
    polygon.points.each do |point|
      visit_point point
    end
    @content += "\n"
  end

  # visit a rectangle
  # @param rectangle [Rectangle] the rectangle to visit
  def visit_rectangle(rectangle)
    @content += "Rectangle: #{rectangle.name}\n"
    visit_point rectangle.start
    @content += "Horizontal: #{rectangle.horizontal}\n"
    @content += "Vertical: #{rectangle.vertical}\n\n"
  end

  # visit a bullseye
  # @param bullseye [Bullseye] the bullseye to visit
  def visit_bullseye(bullseye)
    @content += "Bullseye: #{bullseye.name}\n"
    visit_point bullseye.center
    @content += "Rings: #{bullseye.rings}\n"
    @content += "Distance: #{bullseye.distance}\n\n"
  end

  # visit an ellipse
  # @param ellipse [Ellipse] the ellipse to visit
  def visit_ellipse(ellipse)
    @content += "Ellipse: #{ellipse.name}\n"
    visit_point ellipse.center
    @content += "Horizontal: #{ellipse.horizontal}\n"
    @content += "Vertical: #{ellipse.vertical}\n\n"
  end

  # visit a corridor
  # @param corridor [Corridor] the corridor to visit
  def visit_corridor(corridor)
    @content += "Corridor: #{corridor.name}\n"
    visit_point corridor.start
    visit_point corridor.end
    @content += "Width: #{corridor.width}\n\n"
  end
end

# Convert SITAC objects into KML code
# @autor PRV
# @version 1.0.0
class KMLMaker < Visitor
  include KMLUtils

  attr_reader :content, :name

  def initialize
    super
    @figures = []
  end

  # build the kml file
  # @param figures [Array<Figure>] the list of figures to convert
  # @param name [String] the name of the kml file
  # @return [String] the kml code
  def build(figures, name = "SITAC_#{Time.now.strftime('%Y%m%d_%H%M%S')}")
    @figures = figures
    @name = name
    header
    @figures.each do |figure|
      next if figure.nil?

      figure.accept(self)
    end
    footer
    Log.succ("Successfully built KML code for SITAC #{@name}! It is #{@content.count("\n")} lines long.",
             'CoMe_KMLMaker')
  end

  # export the kml file
  # @param dirname [String] the name of the kml file
  # @return [void]
  def export(dirname)
    # create file
    time = Time.now.strftime('%Y%m%d%H%M%S')
    file = "#{dirname}/#{@name}_#{time}.kml"
    kml_file = File.open(file, 'w')
    kml_file.write(@content)
    kml_file.close
    Log.info("Successfully exported KML file #{file}!", 'CoMe_KMLMaker')

    file
  rescue StandardError => e
    if e.message.include?('No such file or directory')
      # create dir
      dir = File.dirname(file)
      Dir.mkdir(dir) unless File.exist?(dir)
      retry
    end
    Log.err("Cannot create KML file #{filename}! Got error #{e}", 'CoMe_KMLMaker')
  end

  # Generate the header of the kml file
  def header
    hdr_kml = '<?xml version="1.0" encoding="UTF-8"?>
                <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
                <Document>'
    hdr_kml += "<name>#{@name}</name>"
    hdr_file = File.open('lib/raw/styles_sitac.xml', 'r')
    hdr_kml += hdr_file.read.to_s
    @content += hdr_kml
  end

  # Generate the footer of the kml file
  def footer
    ftr = "</Document>
          </kml>"
    @content += ftr
  end

  # Add a point to the kml file
  # @param point [Point] the point to add
  def visit_point(point)
    kml_point = "<Placemark>
                    <name>#{point.name}</name>
                    <styleUrl>#style_placemark</styleUrl>
                    <Point>
                      <coordinates>#{point.longitude},#{point.latitude},0</coordinates>
                    </Point>
                  </Placemark>"
    @content += kml_point
  end

  # Add a line to the kml file
  # @param line [Line] the line to add
  def visit_line(line)
    kml_line = "<Placemark>
                  <name>#{line.name}</name>
                  <styleUrl>#style_line</styleUrl>
                  <LineString>
                    <coordinates>"
    line.points.each do |point|
      kml_line += "#{point.longitude},#{point.latitude},0 "
    end
    kml_line += "</coordinates>
                  </LineString>
                </Placemark>"
    @content += kml_line
  end

  # Add a polygon to the kml file
  # @param polygon [Polygon] the polygon to add
  def visit_polygon(polygon)
    polygon.points << polygon.points[0] if polygon.points[-1] != polygon.points[0]
    kml_poly = "<Placemark>
                <name>#{polygon.name}</name>
                <styleUrl>#style_shape</styleUrl>
                <Polygon>
                  <outerBoundaryIs>
                    <LinearRing>
                      <coordinates>"
    polygon.points.each do |point|
      kml_poly += "#{point.longitude},#{point.latitude},0\n"
    end
    kml_poly += '</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>'
    @content += kml_poly
  end

  # Add a rectangle to the kml file
  # @param rectangle [Rectangle] the rectangle to add
  def visit_rectangle(rectangle)
    start_point = rectangle.start
    rect_points = []
    rect_points << start_point
    rect_points << Point.new('', start_point.latitude + meters_to_degrees(rectangle.vertical), start_point.longitude)
    rect_points << Point.new('', start_point.latitude + meters_to_degrees(rectangle.vertical),
                             start_point.longitude + meters_to_degrees(rectangle.horizontal))
    rect_points << Point.new('', start_point.latitude, start_point.longitude + meters_to_degrees(rectangle.horizontal))
    rect_points << start_point

    visit_polygon(Polygon.new(rectangle.name, rect_points))
  end

  # Add a Bullseye to the kml file
  # @param bullseye [Bullseye] the bullseye to add
  def visit_bullseye(bullseye)
    nil unless bullseye.rings.positive?

    points_thick = []
    points_thin = []

    nb_rings = bullseye.rings
    distance = meters_to_degrees(bullseye.ring_distance) / 2
    radius = meters_to_degrees(bullseye.vradius)
    smallest_radius = radius - (nb_rings * distance)
    center_coords = [bullseye.center.latitude, bullseye.center.longitude]
    # thick lines (main rings, every 2 rings)
    (0..nb_rings).step(2) do |i|
      rad = smallest_radius + i * distance
      points_thick << create_circle(center_coords, rad)
    end
    # thin lines (every other ring)
    (1..nb_rings).step(2) do |i|
      rad = smallest_radius + i * distance
      points_thin << create_circle(center_coords, rad)
    end

    # Build main circles
    kml_bullseye_main = "<Placemark>
                    <name>#{bullseye.name}</name>
                    <styleUrl>#style_bulls</styleUrl>
                    <MultiGeometry>"
    points_thick.each do |point|
      kml_bullseye_main += '<Polygon><outerBoundaryIs><LinearRing><coordinates>'
      point.each do |pt|
        kml_bullseye_main += "#{pt[1]},#{pt[0]},0\n"
      end
      kml_bullseye_main += '</coordinates></LinearRing></outerBoundaryIs></Polygon>'
    end
    kml_bullseye_main += '</MultiGeometry></Placemark>'

    # Build secondary circles
    kml_bulls_secondary = "<Placemark>
                    <name>#{bullseye.name}_second</name>
                    <styleUrl>#style_bulls_thin</styleUrl>
                    <MultiGeometry>"
    points_thin.each do |point|
      kml_bulls_secondary += '<Polygon><outerBoundaryIs><LinearRing><coordinates>'
      point.each do |pt|
        kml_bulls_secondary += "#{pt[1]},#{pt[0]},0\n"
      end
      kml_bulls_secondary += '</coordinates></LinearRing></outerBoundaryIs></Polygon>'
    end
    kml_bulls_secondary += '</MultiGeometry></Placemark>'

    # Build lines
    kml_bulls_cross = "<Placemark>
                    <name>#{bullseye.name}_lines</name>
                    <styleUrl>#style_line</styleUrl>
                    <MultiGeometry>"
    n = 45
    (0..360).step(n) do |i|
      kml_bulls_cross += "<LineString>
                      <coordinates>"
      pt_cross = create_line(center_coords, radius, i)
      pt_cross.each do |pt|
        kml_bulls_cross += "#{pt[1]},#{pt[0]},0\n"
      end
      kml_bulls_cross += '</coordinates></LineString>'
    end

    kml_bulls_cross += '</MultiGeometry></Placemark>'
    @content += kml_bullseye_main + kml_bulls_secondary + kml_bulls_cross
  end

  # Add an ellipse to the kml file
  # @param ellipse [Ellipse] the ellipse to add
  def visit_ellipse(ellipse)
    h_radius = meters_to_degrees(ellipse.hradius)
    v_radius = meters_to_degrees(ellipse.vradius)
    center = [ellipse.center.latitude, ellipse.center.longitude]
    points = create_ellipse(center, h_radius, v_radius)

    kml_ellipse = "<Placemark>
                    <name>#{ellipse.name}</name>
                    <styleUrl>#style_circle</styleUrl>
                    <Polygon>
                      <outerBoundaryIs>
                        <LinearRing>
                          <coordinates>"
    points.each do |point|
      kml_ellipse += "#{point[1]},#{point[0]},0\n"
    end
    kml_ellipse += "</coordinates>
                    </LinearRing>
                  </outerBoundaryIs>
                </Polygon>
              </Placemark>"
    @content += kml_ellipse
  end

  # Add a corridor to the kml file
  # @param corridor [Corridor] the corridor to add
  def visit_corridor(corridor)
    nil # TODO
  end
end

if __FILE__ == $PROGRAM_NAME
  require_relative 'sitac_parser'
  require_relative 'sitac_lexer'

  lexer = XMLLexer.new('input/test.xml')
  tokens = lexer.tokenize
  parser = NorthropParser.new(tokens)
  parser.parse_figures
  figures = parser.figures
  maker = KMLMaker.new
  maker.build(figures, parser.name)
  maker.export('output/test.kml')
end
