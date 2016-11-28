module Ehden
  abstract class Enemy
    getter shooting, pos, dir

    def initialize
      @count = 0
    end

    def render(window)
      @shooting = false
    end
  end
end
