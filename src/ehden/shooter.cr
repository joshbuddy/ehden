module Ehden
  class Shooter < Enemy
    def initialize(@pos : SF::Vector2f, @rate : Int32, @dir : SF::Vector2f)
      super()
    end

    def render(window)
      @count += 1
      @shooting = @count % @rate == 0
    end

    def bullet
      Bullet.new(@pos, @dir)
    end
  end
end
