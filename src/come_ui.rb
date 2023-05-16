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
  $logtext = []

  Val = Struct.new(:logs)

  include Glimmer

  attr_accessor :logs

  def initialize
    @filename = ''
    @outfile = ''
    @logs = [Val.new(['Logs will appear here...', :gray])]
  end

  def launch
    window('CoMe', 720, 480) {
      vertical_box {
        # named label
        @label = label('No file opened yet')
        horizontal_box {
          button('Open') {
            on_clicked do
              @filename = open_file
              next unless @filename

              # update label
              @label.text = "opened file: #{@filename}"
            end
          }
          button('Generate KML') {
            on_clicked do
              next unless @filename

              lexer = XMLLexer.new(@filename, 'ntk')
              tokens = lexer.tokenize

              parser = NorthropParser.new(tokens)
              parser.parse_figures

              kml = KMLMaker.new
              kml.build(parser.figures)
              # ask for output file
              output = save_file
              next unless output

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
        # text area
        # @logs = non_wrapping_multiline_entry {
        #   read_only true
        #   text 'Logs will appear here'
        # }
        table {
          #text_column('Logs')
          text_color_column("Logs")
          editable false
          cell_rows <=> [self, :logs]
        }
      }
      get_stdout

      # DataBinding::Observer.proc do |value|
      #   @logs <=> value
      # end.observe($logtext, :out)

      DataBinding::Observer.proc do |value|
        next if value.last.nil?

        @logs.unshift(value.last)
      end.observe($logtext)

      puts 'CoMe UI initialized'
    }.show
  ensure
    $stdout = STDOUT
  end

  def get_stdout
    # stream stdout to @logtext
    $stdout = StringIO.new
    $stdout.sync = true
    # data stream to @logtext on every write
    $stdout.extend(Module.new {
      def write(str)
        # write on top of @logtext
        # delete color codes
        str = str.gsub(/\e\[(\d+)m/, '')
        # convert to Glimmer string
        # on top of @logtext[:out]
        $logtext << Val.new([str, :blue])
      end
    })
  end
end

CoMe_UI.new.launch
