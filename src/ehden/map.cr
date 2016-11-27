require "crsfml"

module Ehden
  abstract class Map
    TILESET      = SF::Texture.from_file("./src/ehden/tiles/tiles.png")
    SNOW_TILESET = SF::Texture.from_file("./src/ehden/tiles/snow-expansion.png")

    @tile_size = 32
    @tiles = [] of Tile
    @width = 52
    @height = 35
    @position = {0, 0}
    @enemies = [] of Enemy

    def initialize(filepath, @app : App, map_width : Float32, map_height : Float32)
      @render_width = map_width
      @render_height = map_height
      @render_width /= @tile_size
      @render_height /= @tile_size
      @tiles = [] of Tile
      grass = Tile.new(tileset: TILESET, x: 80, y: 80)
      @tile_map = {
        'S' => grass,
        'F' => Tile.new(tileset: SNOW_TILESET, x: 224, y: 208),
        '0' => grass,
        '1' => Tile.new(tileset: TILESET, x: 16, y: 32),
        '2' => Tile.new(tileset: TILESET, x: 32, y: 32),
        '3' => Tile.new(tileset: TILESET, x: 96, y: 32),
        '4' => Tile.new(tileset: TILESET, x: 96, y: 48),
        'X' => Tile.new(tileset: SNOW_TILESET, x: 256, y: 0, passable: false, bg: grass),
        'W' => Tile.new(tileset: SNOW_TILESET, x: 256, y: 48, passable: false, destructible: true, bg: grass),
      }

      @start = SF.vector2f(-1, -1)
      @finish = SF.vector2f(-1, -1)

      load(filepath)
    end

    def start
      @enemies.each do |enemy|
        enemy.start(@app)
      end
    end

    def stop
      @enemies.each do |enemy|
        enemy.stop
      end
    end

    private def load(filepath)
      raw_map = File.read(filepath)

      lines = raw_map.lines.each_with_index do |char_line, y|
        char_line.chomp.each_char_with_index do |c, x|
          @tiles << @tile_map.fetch(c)
          @start = SF.vector2f(x, y) if c == 'S'
          @finish = SF.vector2f(x, y) if c == 'F'
        end
      end
      raise "No start" if @start == SF.vector2f(-1, -1)
      raise "No finish" if @finish == SF.vector2f(-1, -1)
    end

    def start_vector
      SF.vector2f(
        @start.x * @tile_size + @tile_size / 2,
        @start.y * @tile_size + @tile_size / 2,
      )
    end

    def finish_vector
      SF.vector2f(
        @finish.x * @tile_size + @tile_size / 2,
        @finish.y * @tile_size + @tile_size / 2,
      )
    end

    def passable?(rect : SF::Rect)
      top_left = tile_position_at SF.vector2f(rect.left, rect.top)
      bottom_right = tile_position_at SF.vector2f(rect.left + rect.width, rect.top + rect.height)

      (top_left[:x]..bottom_right[:x]).each do |x|
        (top_left[:y]..bottom_right[:y]).each do |y|
          return false unless tile_at(x, y).try &.passable
        end
      end
      return true
    end

    def passable?(point : SF::Vector2f)
      tile_at(**tile_position_at(point)).try &.passable
    end

    def render(window)
      (@position[0]..@render_width + @position[0]).each do |x|
        (@position[1]..@render_height + @position[1]).each do |y|
          tile_at(x, y).try &.render(window, {x * @tile_size, y * @tile_size}, {2, 2})
        end
      end
    end

    def destruct(position)
      xy = tile_position_at(position)
      tile = @tiles[xy[:x] + xy[:y] * @width]
      return false unless tile.destructible
      @tiles[xy[:x] + xy[:y] * @width] = tile.bg || tile
    end

    private def tile_position_at(position)
      {
        x: position.x.to_i / @tile_size,
        y: position.y.to_i / @tile_size,
      }
    end

    private def tile_at(x, y)
      return nil unless (@position[0]..@render_width + @position[0]).includes?(x) && (@position[1]..@render_height + @position[1]).includes?(y)
      @tiles[x + y * @width]
    end
  end
end
