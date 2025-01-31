module Ehden
  module Maps
    class ImpassableObjects < Map
      def initialize(@app : App)
        super("./src/ehden/impassable_objects.level", @app, MAX_WIDTH, MAX_HEIGHT)
        @enemies = [
          Shooter.new(pos: SF.vector2f(50, 50), rate: 100, dir: SF.vector2f(0.4, 0.2)),
          Sprinkler.new(pos: SF.vector2f(250, 250), rate: 250, dir: SF.vector2f(0, 0.2)),
          Shooter.new(pos: SF.vector2f(40, 40), rate: 500, dir: SF.vector2f(0.1, 0.3)),
          Shooter.new(pos: SF.vector2f(606, 600), rate: 500, dir: SF.vector2f(-0.3, -0.2)),
          Sprinkler.new(pos: SF.vector2f(800, 250), rate: 250, dir: SF.vector2f(-0.3, -0.4)),
        ]
      end
    end
  end
end
