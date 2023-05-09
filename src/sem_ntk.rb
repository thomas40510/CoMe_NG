# frozen_string_literal: true

# Semantics for NTK Generated SITAC
class NTKSemantics
  attr_reader :regexes, :sems

  def initialize
    @regexes = {
      beginTag: /<figures>/,
      endTag: %r{</figures>},
      beginFig: /<figure.*>/,
      endFig: %r{</figure>},
      figType: %r{<figureType>(.*)</figureType>},
      figName: %r{<name>(.*)</name>},
      figPoints: %r{<points>(.*)</points>}m,
      figPoint: %r{<point>(.*)</point>},
      ptLatitude: %r{<latitude>(.*)</latitude>},
      ptLongitude: %r{<longitude>(.*)</longitude>},
      figHoriz: %r{<horizontal>(.*)</horizontal>},
      figVert: %r{<vertical>(.*)</vertical>},
      bullseye: %r{<bullseye>(.*)</bullseye>}m,
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
