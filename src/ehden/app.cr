require "crsfml"
require "crsfml/audio"

module Ehden
  abstract class Emitter
    abstract def start(app : App)
  end
  MAX_WIDTH = 800_f32
  MAX_HEIGHT = 800_f32

  class Shooter < Emitter
    def initialize(@pos : SF::Vector2f, @rate : Int32, @dir : SF::Vector2f)
    end

    def start(app)
      spawn do
        loop do
          sleep @rate.milliseconds
          app.add_bullet(@pos, @dir)
        end
      end
    end
  end

  class Sprinkler < Emitter
    @rotation = 0

    def initialize(@pos : SF::Vector2f, @rate : Int32, @dir : SF::Vector2f)
    end

    def start(app)
      spawn do
        loop do
          sleep @rate.milliseconds

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

  class Character
    getter pos, ehden_status

    def initialize(@current : Int32)
      @pos = SF.vector2f(15, 15)
      @alive_texture = SF::Texture.from_file("./src/ehden/ehden_front2.png")
      @dead_texture = SF::Texture.from_file("./src/ehden/ehden_dead2.png")
      @ehden_status = :alive
      @kill_time = 2

      # Create a sprite
      @sprite = SF::Sprite.new
      @sprite.texture = @alive_texture
      @sprite.color = SF.color(255, 255, 255, 200)
      @sprite.position = @pos
    end

    def move(direction : SF::Vector2f, current : Int32)
      revive if @ehden_status == :revivable && direction != SF.vector2f(0, 0)
      return if @ehden_status == :dead
      @pos += direction
      # boundary detection
      @pos.x = 0_f32 if (@pos.x < 0)
      last_x_pos = MAX_WIDTH - 60_f32 #should be sprite width but I'm too lazy to figure that right
      @pos.x = last_x_pos if (@pos.x > last_x_pos)
      @pos.y = 0_f32 if (@pos.y < 0)
      last_y_pos = MAX_HEIGHT - 60_f32 #should be sprite width but I'm too lazy to figure that right
      @pos.y = last_y_pos if (@pos.y > last_y_pos)
      @sprite.position = @pos
      @current = current
    end

    def render(window)
      window.draw @sprite
    end

    def kill
      return if @ehden_status != :alive
      @ehden_status = :dead
      @sprite.texture = @dead_texture
      spawn do
        sleep @kill_time.seconds
        @ehden_status = :revivable
      end
    end

    def revive
      return if @ehden_status != :revivable
      @sprite.texture = @alive_texture
      @ehden_status = :immortal
      spawn do
        sleep 2.seconds
        @ehden_status = :alive
      end
    end
  end

  class Bullet
    property killer = false

    def initialize(@start_time : Int32, @pos : SF::Vector2f, @dir : SF::Vector2f)
    end

    def position(current_time)
      elapsed = current_time - @start_time
      vec = SF.vector2f(@dir.x * elapsed + @pos.x, @dir.y * elapsed + @pos.y)
    end

    def render(window, current : Int32) : SF::Vector2f
      circle = SF::CircleShape.new
      circle.radius = 5
      circle.fill_color = @killer ? SF::Color::Red : SF::Color::White
      circle.position = position(current)
      window.draw circle
      circle.position
    end
  end

  class App
    LEFT  = SF.vector2f(-1, 0)
    UP    = SF.vector2f(0, -1)
    RIGHT = SF.vector2f(1, 0)
    DOWN  = SF.vector2f(0, 1)

    def self.start
      window = SF::RenderWindow.new(SF::VideoMode.new(MAX_WIDTH.to_i, MAX_HEIGHT.to_i), "Slider")
      app = App.new
      while window.open?
        while event = window.poll_event
          if event.is_a? SF::Event::Closed
            window.close
          end
        end

        if app.playing?
          direction = SF.vector2f(0, 0)

          if SF::Joystick.connected?(0)
            position_x = SF::Joystick.get_axis_position(0, SF::Joystick::X)
            position_y = SF::Joystick.get_axis_position(0, SF::Joystick::Y)
            if position_x == 100
              direction.x += 1
            elsif position_x == -100
              direction.x -= 1
            end
            if position_y == 100
              direction.y += 1
            elsif position_y == -100
              direction.y -= 1
            end
          end

          direction.y -= 1 if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Up)
          direction.y += 1 if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Down)
          direction.x -= 1 if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Left)
          direction.x += 1 if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Right)
          app.move(direction)
          app.render(window)
        else
          app.render_title(window)
          if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Space)
            app.start
          elsif SF::Joystick.connected?(0) && SF::Joystick.button_pressed?(0, 0)
            app.start
          end
        end
        window.display
        Fiber.yield
      end
    end

    @title_music = SF::Music.new
    @game_music = SF::Music.new
    @map = Map.new

    def initialize(@bullets = [] of Bullet)
      @playing = false
      @clock = SF::Clock.new
      @character = Character.new(@clock.elapsed_time.as_milliseconds)
      @emitters = [
        Shooter.new(pos: SF.vector2f(50, 50), rate: 1000, dir: SF.vector2f(0.4, 0.2)),
        Sprinkler.new(pos: SF.vector2f(250, 250), rate: 500, dir: SF.vector2f(0, 0.2)),
        Shooter.new(pos: SF.vector2f(40, 40), rate: 1000, dir: SF.vector2f(0.1, 0.3)),
        Shooter.new(pos: SF.vector2f(606, 600), rate: 1000, dir: SF.vector2f(-0.3, -0.2)),
        Sprinkler.new(pos: SF.vector2f(800, 250), rate: 500, dir: SF.vector2f(-0.3, -0.4)),
      ]

      @emitters.each { |e| e.start(self) }

      @title_music.open_from_file("./src/ehden/title.ogg") || raise "no music!"
      @title_music.loop = true # make it loop
      @title_music.play
    end

    def playing?
      @playing
    end

    def start
      @playing = true
      @title_music.stop
      @game_music.open_from_file("./src/ehden/game.ogg") || raise "no music!"
      @game_music.loop = true # make it loop
      @game_music.play
    end

    def render_title(window)
      window.clear SF::Color::Black
      wb_shader = SF::Shader.from_file("./src/ehden/shaders/wave.vert", "./src/ehden/shaders/blur.frag")
      wb_shader.wave_phase @clock.elapsed_time.as_milliseconds
      wb_shader.wave_amplitude 40, 40
      wb_shader.blur_radius 20
      font = SF::Font.from_file("./src/ehden/Cantarell-Regular.otf")
      text = SF::Text.new("EHDEN!!!!", font, 200)
      window.draw text, SF::RenderStates.new(shader: wb_shader)
    end

    def render(window)
      # window.clear SF::Color::Black
      # for debugging
      case @character.ehden_status
      when :alive
        window.clear SF::Color::Black
      when :dead
        window.clear SF::Color::Red
      when :immortal
        window.clear SF::Color::Blue
      when :revivable
        window.clear SF::Color::Green
      end
      current = @clock.elapsed_time.as_milliseconds
      @map.render(window)
      @bullets.each do |bullet|
        position = bullet.render(window, current)
        xdiff = position.x - @character.pos.x
        ydiff = position.y - @character.pos.y
        if (xdiff * xdiff + ydiff * ydiff) < 300
          bullet.render(window, current)
          bullet.killer = true
          @character.kill
        end
      end
      @character.render(window)
    end

    def add_bullet(pos : SF::Vector2f, dir : SF::Vector2f)
      @bullets << Bullet.new(@clock.elapsed_time.as_milliseconds, pos, dir)
    end

    def move(direction : SF::Vector2f)
      @character.move(direction, @clock.elapsed_time.as_milliseconds)
    end
  end
end
