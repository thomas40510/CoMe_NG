# frozen_string_literal: true

require_relative 'sitac_objects'
require_relative 'sitac_lexer'
require_relative 'sitac_parser'
require_relative 'kml_maker'
require_relative 'ast'
require_relative 'log_utils'

# Main file for CoMe_NG

# CL format : ruby come_ng.rb <file.xml> -o [file.kml] -s [ntk/melissa] -n [name]
# -o : output file
# -s : syntax (ntk/melissa)
# -n : name of the file
# -h : help

# default values
output = "sitac_#{Time.now.strftime('%Y%m%d%H%M%S')}.kml"
name = "sitac_#{Time.now.strftime('%Y%m%d%H%M%S')}"
type = 'ntk'
show_ast = false


# read command line arguments
args = ARGV
args.each do |arg|
  if arg == '-h'
    puts 'Usage: ruby come_ng.rb <file.xml> -o [file.kml] -s [ntk/melissa]'
    puts '-o : output file'
    puts '-s : syntax (ntk/melissa)'
    puts '-a : prettyprint the AST'
    puts '-h : help'
    exit
  end

  output = args[args.index(arg) + 1] if arg == '-o'

  if arg == '-s'
    # TODO: implment Melissa semantics
    nil
  end

  show_ast = arg == '-a'

rescue StandardError => e
  Log.err("Unknown request (#{e})", 'CoMe_NG')
  exit
end

lexer = XMLLexer.new(ARGV[0], 'ntk')
tokens = lexer.tokenize

parser = NorthropParser.new(tokens)
parser.parse_figures

if show_ast
  ast = ASTTree.new
  ast.build(parser.figures)
  ast.pretty_print
else
  kmlmaker = KMLMaker.new
  kmlmaker.build(parser.figures, name)

  kmlmaker.export(output)
end




