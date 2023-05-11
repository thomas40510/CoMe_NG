# frozen_string_literal: true

# Generic Semantics class
class Semantics
  attr_reader :regexes, :sems

  def initialize
    @regexes = {}
    @sems = {}
  end

  def sems_and_regexes
    [@sems, @regexes]
  end
end

# Semantics for Melissa Generated SITAC
# TODO: implement
class MelissaSemantics < Semantics
  def initialize
    super
    @regexes = nil
    @sems = nil
  end
end

# Semantics for NTK Generated SITAC
class NTKSemantics < Semantics
  def initialize
    super
    @regexes = {
      body: %r{<figures>((.|\n)*)</figures>},
      figure: %r{<figure .*?>((.|\n)*?)</figure>},
      figType: %r{<figureType>(.*)</figureType>},
      figName: %r{<name>(.*)</name>},
      figHoriz: %r{<horizontal>(.*)</horizontal>},
      figVert: %r{<vertical>(.*)</vertical>},
      figPoints: %r{<points>((.|\n)*)</points>},
      figPoint: %r{<point>((.|\n)*?)</point>},
      ptLatitude: %r{<latitude>(.*)</latitude>},
      ptLongitude: %r{<longitude>(.*)</longitude>},
      bullseye: %r{<bullseye>(.*)</bullseye>},
      bullsRings: %r{<numberOfRings>(.*)</numberOfRings>},
      bullsDist: %r{<distanceBetweenRing>(.*)</distanceBetweenRing>}
    }
    @sems = {}
    @regexes.each do |key, value|
      @sems[key] = value.to_s.scan(/<(.*)>/).first.first.to_sym
    end
  end
end
