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

# GUI for CoMe_NG
# @version 1.2.0
# @author PRV
# @date 2023
class CoMe_UI
  include Glimmer

  @@logtext = []

  # Constants
  BG_COLOR = :ghost_white
  COLORDEFS = {
    red: "\e[31m",
    green: "\e[32m",
    blue: "\e[34m"
  }.freeze

  # Datastructure for log entries
  LogEntry = Struct.new(:logs, :background_color)


  attr_accessor :logs

  # Initialize vars and launch the UI
  def initialize
    @filename = ''
    @outfile = ''
    @logs = [LogEntry.new(['⬆️ Logs will appear above ⬆️', :black], BG_COLOR)]
    @logs << LogEntry.new(['=======================', :black], BG_COLOR)
    @logs = @logs.reverse

    launch
  end

  # Create a UI window and display it
  def launch
    @window = create_window
    @window.show
  ensure
    # redirect $stdout to original stream upon closing
    $stdout = STDOUT
  end

  # Create the UI window with its elements and logic.
  # @note It follows the Glimmer DSL syntax.
  # @see https://github.com/AndyObtiva/glimmer-dsl-libui
  # @return [UI::Window] the UI window
  def create_window
    window('CoMe', 720, 480) do
      margined true

      vertical_box do
        @label = label('No file opened yet')
        horizontal_box do
          button('Open') do
            on_clicked do
              @filename = open_file
              next unless @filename

              # update label
              @label.text = "📖 Opened file: #{@filename}"
            end
          end
          button('Generate KML') do
            on_clicked do
              next unless @filename

              # lexer
              lexer = XMLLexer.new(@filename, 'ntk')
              tokens = lexer.tokenize

              # parser
              parser = NorthropParser.new(tokens)
              parser.parse_figures

              # make kml
              kml = KMLMaker.new
              kml.build(parser.figures)
              # ask for output file
              output = save_file # TODO: ask for dir instead, and save with generated filename
              next unless output

              output += '.kml' unless output.include?('.kml')
              # write kml to file
              kml.export(output)
              @outfile = output

              # update label
              @label.text = "✅ Generated file: #{output}"
              @openbtn.enabled = true
            end
          end
          @openbtn = button('Show in Finder') do
            next unless @outfile

            # get system type (Darwin, Linux, Windows)
            sysname = RbConfig::CONFIG['host_os']

            on_clicked do
              case sysname
              when /darwin/
                system("open -R #{@outfile}") # open file in finder
              when /linux/
                system("xdg-open #{@outfile}") # open file in file manager
              when /mswin|mingw|cygwin/
                system("explorer #{@outfile}") # open file in explorer
              else
                Log.err('Unsupported OS', 'CoMe')
              end
            end
          end
          @openbtn.enabled = false
        end
        # display $stdout in a pretty colored table
        table do
          background_color_column
          text_color_column("Logs")
          editable false
          # bind to @logs
          cell_rows <=> [self, :logs]
        end
      end

      get_stdout

      # observe @@logtext for changes
      DataBinding::Observer.proc do |value|
        next if value.last.nil?

        @logs.unshift(value.last)
      end.observe(@@logtext)

      puts 'CoMe UI initialized'
    end

  end

  # Redirect $stdout and write to @@logtext
  def get_stdout
    $stdout = StringIO.new
    $stdout.sync = true

    # data stream to @logtext on every write
    $stdout.extend(Module.new do
      def write(str)
        # get color key from color codes
        color = COLORDEFS.key(str.match(/\e\[(\d+)m/).to_s)
        # delete color codes
        str = str.gsub(/\e\[(\d+)m/, '')

        # add to @@logtext
        @@logtext << LogEntry.new([str, color], BG_COLOR)
      end
    end)
  end
end

CoMe_UI.new
