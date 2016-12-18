module Ehden
  module Maps
    class FloweyEncounter1 < Map
      def initialize(@app : App)
        super("./src/ehden/flowey_encounter_1.level", @app, MAX_WIDTH, MAX_HEIGHT)
        @enemies = [
          Shooter.new(pos: SF.vector2f(50, 50), rate: 500, dir: SF.vector2f(0.4, 0.2)),
          Sprinkler.new(pos: SF.vector2f(250, 250), rate: 250, dir: SF.vector2f(0, 0.2)),
          Shooter.new(pos: SF.vector2f(40, 40), rate: 500, dir: SF.vector2f(0.1, 0.3)),
          Shooter.new(pos: SF.vector2f(606, 600), rate: 500, dir: SF.vector2f(-0.3, -0.2)),
          Sprinkler.new(pos: SF.vector2f(800, 250), rate: 250, dir: SF.vector2f(-0.3, -0.4)),
          Shooter.new(pos: SF.vector2f(100,150), rate: 50, dir: SF.vector2f(0.1, 0.5)),
           Shooter.new(pos: SF.vector2f(600,150), rate: 50, dir: SF.vector2f(-0.1, 0.5)),
        ]
      end
    end
  end
end
