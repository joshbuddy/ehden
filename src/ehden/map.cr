module Ehden
  class Map
    abstract class Tile
      abstract def sprite : SF::Sprite

      TILESET = SF::Texture.from_file("./src/ehden/tiles/tiles.png")
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

    getter start_percent_of, finish_percent_of

    @tile_size = 32
    @tiles = [] of Tile
    @width = 52
    @height = 35
    @position = {0, 0}

    def initialize(filepath)
      @render_width = 25.0
      @render_height = 25.0
      @tiles = [] of Tile
      tile_map = {
        'S' => Grass.new,
        'F' => Grass.new,
        '0' => Grass.new,
        '1' => GrassTopLeft.new,
        '2' => GrassTop.new,
        '3' => GrassTopRight.new,
        '4' => GrassRight.new,
      }

      raw_map = File.read(filepath)

      @start_percent_of = SF.vector2f(-1,-1)
      @finish_percent_of = SF.vector2f(-1,-1)

      lines = raw_map.lines.each_with_index do |char_line, y|
        char_line.chomp.each_char_with_index do |c, x|
          @tiles << tile_map.fetch(c)
          @start_percent_of = SF.vector2f(x/@render_width,y/@render_height) if c == 'S'
          @finish_percent_of = SF.vector2f(x/@render_width,y/@render_height) if c == 'F'
        end
      end
      puts "No start" if @start_percent_of == SF.vector2f(-1,-1)
      puts "No finish" if @finish_percent_of == SF.vector2f(-1,-1)
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
