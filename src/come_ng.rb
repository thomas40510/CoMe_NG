# frozen_string_literal: true

require_relative 'sitac_objects'
require_relative 'sitac_lexer'
require_relative 'sitac_parser'
require_relative 'kml_maker'
require_relative 'ast'
require_relative 'log_utils'

lexer = XMLLexer.new('input/test.xml')
tokens = lexer.tokenize
parser = NorthropParser.new(tokens)
parser.parse_figures
figures = parser.figures
maker = KMLMaker.new
maker.build(figures, parser.name)

tree = ASTTree.new
tree.build(figures)
puts tree.pretty_print

