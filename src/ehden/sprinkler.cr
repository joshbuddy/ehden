module Ehden
  class Sprinkler < Enemy
    @rotation = 0

    ROTATION_SPEED = 5000

    def initialize(@pos : SF::Vector2f, @rate : Int32, @dir : SF::Vector2f)
      super()
    end

    def render(window)
      @count += 1
      @rotation += 1
      @rotation = 0 if @rotation == ROTATION_SPEED
      @shooting = @count % @rate == 0
    end

    def bullet
      cos = Math.cos(Math::PI * 2 * @rotation.to_f / ROTATION_SPEED)
      sin = Math.sin(Math::PI * 2 * @rotation.to_f / ROTATION_SPEED)
      dir = SF.vector2f(
        @dir.x * cos - @dir.y * sin,
        @dir.x * sin + @dir.y * cos,
      )
      Bullet.new(@pos, dir)
    end
  end
end
