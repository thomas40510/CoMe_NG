# frozen_string_literal: true

# Parser module for Melissa Converter NG
# @note This module contains the parser and its subclasses
# @author PRV
# @version 1.0.0
# @date 2023
module SITACParser
  class ParsingException < StandardError
    nil
  end

  # Parser for SITAC files
  # @note This class is used to parse a SITAC file and identify its objects
  # @author PRV
  # @version 1.0.0
  # @date 2023
  class NorthropParser
    # @param [Object] lexems
    def initialize(lexems)
      printf("=== Parsing ===\n")
      @lexems = lexems
      @position = 0
      @sems, @regexes = NTKSemantics.new.sems_and_regexes
      puts "Semantic: #{@sems}"
    end

    def read_lexem
      @lexems.pop(0)
    end
  end
end
