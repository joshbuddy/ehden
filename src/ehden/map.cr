require "crsfml"

module Ehden
  class Map
    abstract class Tile
      abstract def sprite : SF::Sprite

      TILESET = SF::Texture.from_file("./src/ehden/tiles/tiles.png")
      SNOW_TILESET = SF::Texture.from_file("./src/ehden/tiles/snow-expansion.png")
    end

    class Grass < Tile
      getter sprite

      @sprite = SF::Sprite.new(TILESET, SF.int_rect(80, 80, 16, 16))
    end

    class GrassTop < Tile
      getter sprite

      @sprite = SF::Sprite.new(TILESET, SF.int_rect(32, 32, 16, 16))
    end

    class GrassTopLeft < Tile
      getter sprite

      @sprite = SF::Sprite.new(TILESET, SF.int_rect(16, 32, 16, 16))
    end

    class GrassLeft < Tile
      getter sprite

      @sprite = SF::Sprite.new(TILESET, SF.int_rect(16, 32, 16, 16))
    end

    class GrassTopRight < Tile
      getter sprite

      @sprite = SF::Sprite.new(TILESET, SF.int_rect(96, 32, 16, 16))
    end

    class GrassRight < Tile
      getter sprite

      @sprite = SF::Sprite.new(TILESET, SF.int_rect(96, 48, 16, 16))
    end

    class EndTile < Tile
      getter sprite

      @sprite = SF::Sprite.new(SNOW_TILESET, SF.int_rect(224, 208, 16, 16))
    end

    @tile_size = 32
    @tiles = [] of Tile
    @width = 52
    @height = 35
    @position = {0, 0}

    def initialize(filepath, map_width : Float32, map_height : Float32)
      @render_width = map_width
      @render_height = map_height
      @render_width /= @tile_size
      @render_height /= @tile_size
      @tiles = [] of Tile
      tile_map = {
        'S' => Grass.new,
        'F' => EndTile.new,
        '0' => Grass.new,
        '1' => GrassTopLeft.new,
        '2' => GrassTop.new,
        '3' => GrassTopRight.new,
        '4' => GrassRight.new,
      }

      raw_map = File.read(filepath)

      @start = SF.vector2f(-1,-1)
      @finish = SF.vector2f(-1,-1)

      lines = raw_map.lines.each_with_index do |char_line, y|
        char_line.chomp.each_char_with_index do |c, x|
          @tiles << tile_map.fetch(c)
          @start = SF.vector2f(x, y) if c == 'S'
          @finish = SF.vector2f(x, y) if c == 'F'
        end
      end
      raise "No start" if @start == SF.vector2f(-1,-1)
      raise "No finish" if @finish == SF.vector2f(-1,-1)
    end

    def start
      SF.vector2f(
        @start.x * @tile_size + @tile_size / 2,
        @start.y * @tile_size + @tile_size / 2,
      )
    end

    def finish
      SF.vector2f(
        @finish.x * @tile_size + @tile_size / 2,
        @finish.y * @tile_size + @tile_size / 2,
      )
    end

    def tile_at(x, y)
      @tiles[y / @tile_size * @width + x / @tile_size]
    end

    def render(window)
      (@position[0]..@render_width + @position[0]).each do |x|
        (@position[1]..@render_height + @position[1]).each do |y|
          tile = @tiles[x + y * @width]
          tile.sprite.position = {x * @tile_size, y * @tile_size}
          tile.sprite.scale = {2, 2}
          window.draw tile.sprite
        end
      end
    end
  end
end
