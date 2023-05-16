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
  @@logtext = []

  BG_COLOR = :ghost_white
  COLORDEFS = {
    red: "\e[31m",
    green: "\e[32m",
    blue: "\e[34m"
  }.freeze

  LogEntry = Struct.new(:logs, :background_color)

  include Glimmer

  attr_accessor :logs

  def initialize
    @filename = ''
    @outfile = ''
    @logs = [LogEntry.new(['⬆️ Logs will appear above ⬆️', :black], BG_COLOR)]
    @logs << LogEntry.new(['=======================', :black], BG_COLOR)
    @logs = @logs.reverse

    launch
  end

  def launch
    @window = window('CoMe', 720, 480) do
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

              # execute CoMe
              lexer = XMLLexer.new(@filename, 'ntk')
              tokens = lexer.tokenize

              parser = NorthropParser.new(tokens)
              parser.parse_figures

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
    @window.show
  ensure
    $stdout = STDOUT
  end

  # Redirect $stdout and write to @@logtext
  # @return [void]
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
