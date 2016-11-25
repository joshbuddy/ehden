require "crsfml"
require "crsfml/audio"

module Ehden
  abstract class Emitter
    abstract def start(app : App)
  end

  MAX_WIDTH  = 800_f32
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
    property facing

    @dead_music = SF::Music.new

    def initialize(@current : Int32, @pos : SF::Vector2f)
      @alive_texture = SF::Texture.from_file("./src/ehden/ehden_front2.png")
      @dead_texture = SF::Texture.from_file("./src/ehden/ehden_dead2.png")
      @ehden_status = :alive
      @kill_time = 3
      @dead_music.open_from_file("./src/ehden/dead.ogg") || raise "no music!"
      @facing = SF::Vector2f.new
      @last_swing = @current

      # Create a sprite
      @sprite = SF::Sprite.new
      @sprite.texture = @alive_texture
      @sprite.color = SF.color(255, 255, 255, 200)
      @sprite.position = @pos
    end

    def move(pos, current)
      @sprite.position = @pos = pos
      @current = current
    end

    def face(pos, current)
      @sprite.position = @pos = pos
      @current = current
    end

    def swing
      if @current - @last_swing > 1000
        @last_swing = @current
      end
    end

    def boundaries(pos = @pos)
      SF::Rect(Int32).new(11 + pos.x.to_i, 1 + pos.y.to_i, 25, 58)
    end

    def sword
      SF::Rect(Int32).new(
        -3 + (@pos.x + @facing.x * 50).to_i,
        1 + (@pos.y + @facing.y * 50).to_i,
        50,
        50
      )
    end

    def render(window)
      window.draw @sprite
    end

    def kill
      return if @ehden_status != :alive
      @ehden_status = :dead
      @sprite.texture = @dead_texture
      @dead_music.play
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
    getter pos
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
    MAPS  = [["./src/ehden/first_room.level", "map"], ["./src/ehden/second_room.level", "map"], ["./src/ehden/flowey_encounter_1.level", "speech"]]

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
          app.swing if SF::Keyboard.key_pressed?(SF::Keyboard::Key::Space)
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

    def initialize(@bullets = [] of Bullet)
      @current_level = 0
      @playing = false
      @clock = SF::Clock.new
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

    def sword_hit
      @sword_hit ||= SF::Music.from_file("./src/ehden/sword_hit.ogg")
    end

    def sword_miss
      @sword_miss ||= SF::Music.from_file("./src/ehden/sword_miss.ogg")
    end

    def character
      @character ||= Character.new(@clock.elapsed_time.as_milliseconds, map.start)
    end

    def map
      map = @map
      if @loaded_level != @current_level
        @loaded_level = @current_level
        map = nil
      end
      @map = map || Map.new(MAPS[@current_level][0], MAX_WIDTH, MAX_HEIGHT)
    end

    def next_map
      @current_level += 1
      character.move(map.start, @clock.elapsed_time.as_milliseconds)
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
      instructions = SF::Text.new("Dodge bullets, press button and swing bullets at rocks1", font, 40)
      instructions.position = {100, 400}
      window.draw instructions
    end

    def render(window)
      # window.clear SF::Color::Black
      # for debugging
      case character.ehden_status
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
      map.render(window)
      @bullets.each do |bullet|
        position = bullet.render(window, current)
        if (character.boundaries.contains? position)
          bullet.killer = true
          character.kill
        end
        if (!map.passable? position)
          @bullets.delete(bullet)
          map.destruct position
        end
      end
      character.render(window)
    end

    def add_bullet(pos : SF::Vector2f, dir : SF::Vector2f)
      @bullets << Bullet.new(@clock.elapsed_time.as_milliseconds, pos, dir)
    end

    def move(direction : SF::Vector2f)
      character.revive if character.ehden_status == :revivable && direction != SF.vector2f(0, 0)
      return if character.ehden_status == :dead

      pos = character.pos
      pos += direction
      # boundary detection
      pos.x = 0_f32 if (pos.x < 0)
      last_x_pos = MAX_WIDTH - 60_f32 # should be sprite width but I'm too lazy to figure that right
      pos.x = last_x_pos if (pos.x > last_x_pos)
      pos.y = 0_f32 if (pos.y < 0)
      last_y_pos = MAX_HEIGHT - 60_f32 # should be sprite width but I'm too lazy to figure that right
      pos.y = last_y_pos if (pos.y > last_y_pos)

      if map.passable? character.boundaries(pos)
        character.move(pos, @clock.elapsed_time.as_milliseconds)
        character.facing = direction if direction.x.abs + direction.y.abs > 0
        # go to next map if character walks close enough to the end marker
        next_map if character.boundaries.contains? map.finish
      end
    end

    def swing
      if character.swing
        hit = false
        @bullets.each_with_index do |bullet, b|
          pos = bullet.position(@clock.elapsed_time.as_milliseconds)
          if character.sword.contains? pos
            @bullets[b] = Bullet.new(
              @clock.elapsed_time.as_milliseconds,
              pos,
              (character.pos + {23, 30} - pos) / -30
            )
            hit = true
            break
          end
        end
        if hit
          sword_hit.play if sword_hit.status == SF::SoundSource::Stopped
        else
          sword_miss.play if sword_miss.status == SF::SoundSource::Stopped
        end
      end
    end
  end
end
