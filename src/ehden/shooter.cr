module Ehden
  class Shooter < Enemy
    def initialize(@pos : SF::Vector2f, @rate : Int32, @dir : SF::Vector2f)
    end

    def start(app)
      spawn do
        loop do
          sleep @rate.milliseconds
          app.add_bullet(@pos, @dir) if app.playing?
        end
      end
    end
  end
end
