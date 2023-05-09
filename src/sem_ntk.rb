# frozen_string_literal: true

# Semantics for NTK Generated SITAC
class NTKSemantics
  attr_reader :regexes, :sems

  def initialize
    @regexes = {
      body: %r{<figures>((.|\n)*)</figures>},
      figure: %r{<figure.*?>((.|\n)*)</figure>},
      figType: %r{<figureType>(.*)</figureType>},
      figName: %r{<name>(.*)</name>},
      figHoriz: %r{<horizontal>(.*)</horizontal>},
      figVert: %r{<vertical>(.*)</vertical>},
      figPoints: %r{<points>((.|\n)*)</points>},
      figPoint: %r{<point>((.|\n)*)</point>},
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

  def sems_and_regexes
    [@sems, @regexes]
  end
end
