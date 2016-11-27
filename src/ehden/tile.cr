module Ehden
  class Tile
    getter sprite, passable, bg, destructible

    def initialize(tileset, x, y, width = 16, height = 16, @passable : Bool = true, @destructible : Bool = false, @bg : Tile | Nil = nil)
      @sprite = SF::Sprite.new(tileset, SF.int_rect(x, y, width, height))
      @sprite.scale = {2, 2}
    end

    def render(window, position, scale)
      sprite.position = position
      bg.try &.render(window, position, scale)
      window.draw sprite
    end
  end
end
