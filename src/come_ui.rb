# frozen_string_literal: true

# @see https://github.com/kojix2/libui
# @see https://github.com/AndyObtiva/glimmer-dsl-libui

require 'glimmer-dsl-libui'

require_relative 'sitac_objects'
require_relative 'sitac_lexer'
require_relative 'sitac_parser'
require_relative 'kml_maker'
require_relative 'ast'
require_relative 'log_utils'


class CoMe_UI
  include Glimmer

  def initialize
    @filename = ''
    @outfile = ''

    window('CoMe', 300, 200) {
      vertical_box {
        # named label
        @label = label('No file opened yet')
        horizontal_box {
          button('Open') {
            on_clicked do
              @filename = open_file
              # update label
              @label.text = "opened file: #{@filename}"
            end
          }
          button('Generate KML') {
            on_clicked do
              lexer = XMLLexer.new(@filename, 'ntk')
              tokens = lexer.tokenize

              parser = NorthropParser.new(tokens)
              parser.parse_figures

              kml = KMLMaker.new
              kml.build(parser.figures)
              # ask for output file
              output = save_file
              output += '.kml' unless output.include?('.kml')
              # write kml to file
              kml.export(output)
              @outfile = output

              # update label
              @label.text = "generated file: #{output}"
              @openbtn.enabled = true
            end
          }
          @openbtn = button('Show in Finder') {
            on_clicked do
              puts "open -R #{@outfile}"
              system("open -R #{@outfile}")
            end
          }
          @openbtn.enabled = false
        }
      }
    }.show
  end
end

CoMe_UI.new
