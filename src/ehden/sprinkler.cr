module Ehden
  class Sprinkler < Enemy
    @rotation = 0

    def initialize(@pos : SF::Vector2f, @rate : Int32, @dir : SF::Vector2f)
    end

    def start(app)
      spawn do
        loop do
          sleep @rate.milliseconds
          if app.playing?
            cos = Math.cos(Math::PI * 2 * @rotation.to_f / 100)
            sin = Math.sin(Math::PI * 2 * @rotation.to_f / 100)
            dir = SF.vector2f(
              @dir.x * cos - @dir.y * sin,
              @dir.x * sin + @dir.y * cos,
            )
            @rotation += 1
            @rotation = 0 if @rotation == 100
            app.add_bullet(@pos, dir)
          end
        end
      end
    end
  end
end
