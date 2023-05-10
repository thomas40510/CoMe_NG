# frozen_string_literal: true

require_relative 'sitac_objects'
require_relative 'log_utils'

# Utilities for KML generation
# @version 1.0.0
# @date 2023
module KMLUtils
  def meters_to_degrees(meters)
    meters / 111_111
  end

  # Create circle around a center
  def create_circle(center, radius, nb_points = 300)
    x, y = center
    points = []
    angle_step = 2 * Math::PI / nb_points
    nb_points.times do |i|
      points << [x + radius * Math.cos(i * angle_step), y + radius * Math.sin(i * angle_step)]
    end
    points
  end

  def create_ellipse(center, hradius, vradius, angle = 0, nb_points = 100)
    x, y = center
    points = []
    start_angle = 0
    angle_step = 2 * Math::PI / nb_points
    nb_points.times do
      points << [x + hradius * Math.cos(start_angle), y + vradius * Math.sin(start_angle)]
      start_angle += angle_step
    end
    points << points[0]
    points
  end

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

  def visit_point(point)
    @content += "Point: #{point.name} (#{point.latitude}, #{point.longitude})\n"
  end

  def visit_line(line)
    @content += "Line: #{line.name}\n"
    line.points.each do |point|
      visit_point point
    end
    @content += "\n"
  end

  def visit_polygon(polygon)
    @content += "Polygon: #{polygon.name}\n"
    polygon.points.each do |point|
      visit_point point
    end
    @content += "\n"
  end

  def visit_rectangle(rectangle)
    @content += "Rectangle: #{rectangle.name}\n"
    visit_point rectangle.start
    @content += "Horizontal: #{rectangle.horizontal}\n"
    @content += "Vertical: #{rectangle.vertical}\n\n"
  end

  def visit_bullseye(bullseye)
    @content += "Bullseye: #{bullseye.name}\n"
    visit_point bullseye.center
    @content += "Rings: #{bullseye.rings}\n"
    @content += "Distance: #{bullseye.distance}\n\n"
  end

  def visit_ellipse(ellipse)
    @content += "Ellipse: #{ellipse.name}\n"
    visit_point ellipse.center
    @content += "Horizontal: #{ellipse.horizontal}\n"
    @content += "Vertical: #{ellipse.vertical}\n\n"
  end

  def visit_corridor(corridor)
    @content += "Corridor: #{corridor.name}\n"
    visit_point corridor.start
    visit_point corridor.end
    @content += "Width: #{corridor.width}\n\n"
  end
end

# Convert SITAC objects into KML code
class KMLMaker < Visitor
  include KMLUtils

  attr_reader :content

  def initialize
    super
    @figures = []
  end

  def build(figures)
    @figures = figures
    header
    @figures.each do |figure|
      next if figure.nil?

      figure.accept(self)
    end
    footer
  end

  def export(filename)
    # create file
    kml_file = File.open(filename, 'w')
    kml_file.write(@content)
    kml_file.close

  rescue StandardError => e
    if e.message.include?('No such file or directory')
      # create dir
      dir = File.dirname(filename)
      Dir.mkdir(dir) unless File.exist?(dir)
      retry
    end
    Log.err("Cannot create KML file #{filename}! Got error #{e}", 'CoMe_KMLMaker')
  end

  def header
    hdr_file = File.open('src/raw/hdrsitac.txt', 'r')
    hdr = hdr_file.read
    @content += hdr.to_s
  end

  def footer
    ftr = "</Document>
          </kml>"
    @content += ftr
  end

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

  def visit_rectangle(rectangle)
    startpt = rectangle.start
    rectpoints = []
    rectpoints << startpt
    rectpoints << Point.new('', startpt.latitude + meters_to_degrees(rectangle.vertical), startpt.longitude)
    rectpoints << Point.new('', startpt.latitude + meters_to_degrees(rectangle.vertical),
                            startpt.longitude + meters_to_degrees(rectangle.horizontal))
    rectpoints << Point.new('', startpt.latitude, startpt.longitude + meters_to_degrees(rectangle.horizontal))
    rectpoints << startpt

    visit_polygon(Polygon.new(rectangle.name, rectpoints))
  end

  def visit_bullseye(bullseye)
    nil unless bullseye.rings.positive?

    points_thick = []
    points_thin = []

    nbrings = bullseye.rings
    distance = meters_to_degrees(bullseye.ring_distance) / 2
    radius = meters_to_degrees(bullseye.vradius)
    smallest_radius = radius - (nbrings * distance)
    center_coords = [bullseye.center.latitude, bullseye.center.longitude]
    # thick lines (main rings, every 2 rings)
    (0..nbrings).step(2) do |i|
      rad = smallest_radius + i * distance
      points_thick << create_circle(center_coords, rad)
    end
    # thin lines (every other ring)
    (1..nbrings).step(2) do |i|
      rad = smallest_radius + i * distance
      points_thin << create_circle(center_coords, rad)
    end

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

  def visit_ellipse(ellipse)
    hradius = meters_to_degrees(ellipse.hradius)
    vradius = meters_to_degrees(ellipse.vradius)
    center = [ellipse.center.latitude, ellipse.center.longitude]
    points = create_ellipse(center, hradius, vradius)

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

  def visit_corridor(corridor)
    nil
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
  maker.build(figures)
  maker.export('output/test.kml')
end
