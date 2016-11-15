require "crsfml"
require "crsfml/audio"

module Ehden
  class Emitter
    def initialize(@app : App, @pos : SF::Vector2f, @rate : Int32, @dir : SF::Vector2f)
      spawn do
        loop do
          sleep @rate.milliseconds
          @app.add_bullet(@pos, @dir)
        end
      end
    end
  end

  class Character
    getter pos

    def initialize(@current : Int32)
      @pos = SF.vector2f(30, 30)
      texture = SF::Texture.from_file("./src/ehden/ehden_front.png")
      @dead_texture = SF::Texture.from_file("./src/ehden/ehden_dead.png")
      @dead = false

      # Create a sprite
      @sprite = SF::Sprite.new
      @sprite.texture = texture
      @sprite.texture_rect = SF.int_rect(10, 10, 50, 30)
      @sprite.color = SF.color(255, 255, 255, 200)
      @sprite.position = @pos
    end

    def move(direction : SF::Vector2f, current : Int32)
      return if @dead
      elapsed = current - @current
      @pos += direction
      @sprite.position = @pos
      @current = current
    end

    def render(window)
      window.draw @sprite
    end

    def kill
      return if @dead
      @dead = true
      @sprite.texture = @dead_texture
    end
  end

  class Bullet
    def initialize(@start_time : Int32, @pos : SF::Vector2f, @dir : SF::Vector2f)
    end

    def position(current_time)
      elapsed = current_time - @start_time
      vec = SF.vector2f(@dir.x * elapsed + @pos.x, @dir.y * elapsed + @pos.y)
    end
  end

  class App
    def self.start
      window = SF::RenderWindow.new(SF::VideoMode.new(800, 800), "Slider")
      app = App.new
      while window.open?
        while event = window.poll_event
          if event.is_a? SF::Event::Closed
            window.close
          end
        end

        if app.playing?
          direction = SF.vector2f(0, 0)
          direction.y -= 1 if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Up)
          direction.y += 1 if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Down)
          direction.x -= 1 if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Left)
          direction.x += 1 if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Right)
          app.move(direction)
          app.render(window)
          window.display
          Fiber.yield
        else
          app.render_title(window)
          app.start if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Space)
        end
      end
    end

    @title_music = SF::Music.new
    @game_music = SF::Music.new

    def initialize(@bullets = [] of Bullet)
      @playing = false
      @clock = SF::Clock.new
      @character = Character.new(@clock.elapsed_time.as_milliseconds)
      @emitters = [
        Emitter.new(self, pos: SF.vector2f(50, 50), rate: 500, dir: SF.vector2f(0.4, 0.2)),
        Emitter.new(self, pos: SF.vector2f(250, 250), rate: 500, dir: SF.vector2f(0, 0.2)),
        Emitter.new(self, pos: SF.vector2f(40, 40), rate: 500, dir: SF.vector2f(0.1, 0.3)),
        Emitter.new(self, pos: SF.vector2f(606, 600), rate: 100, dir: SF.vector2f(-0.3, -0.2)),
        Emitter.new(self, pos: SF.vector2f(800, 250), rate: 500, dir: SF.vector2f(-0.3, -0.4)),
      ]

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
      window
    end

    def render(window)
      window.clear SF::Color::Black
      current = @clock.elapsed_time.as_milliseconds
      circle = SF::CircleShape.new
      circle.radius = 5
      circle.fill_color = SF::Color::Red
      @bullets.each do |bullet|
        position = bullet.position(current)
        if position.x - 5 < @character.pos.x && position.x + 5 > @character.pos.x && position.y - 5 < @character.pos.y && position.y + 5 > @character.pos.y
          @character.kill
        end
        circle.position = position
        window.draw circle
        if position.x < 0 && position.y < 0
          @bullets.delete(bullet)
        elsif position.x > 800 && position.y > 800
          @bullets.delete(bullet)
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
