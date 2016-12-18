module Ehden
  class Character
    getter status, lives
    property pos, facing

    @dead_music = SF::Music.new
    @count = 0

    def initialize
      @lives = 3
      @alive_texture = SF::Texture.from_file("./src/ehden/ehden_front2.png")
      @shield_texture = SF::Texture.from_file("./src/ehden/ehden_shield.png")
      @dead_texture = SF::Texture.from_file("./src/ehden/ehden_dead2.png")
      @pos = SF.vector2f(0, 0)
      @status = :alive
      @kill_time = 3
      @dead_music.open_from_file("./src/ehden/dead.ogg") || raise "no music!"
      @facing = SF::Vector2f.new

      # Create a sprite
      @sprite = SF::Sprite.new
      @sprite.color = SF.color(255, 255, 255, 200)
      @sprite.position = @pos
      @swinging = false
    end

    def move(pos)
      @count += 1
      @sprite.position = @pos = pos
    end

    def swing
      return false if @swinging || @status == :dead
      spawn do
        sleep 1
        @swinging = false
      end
      @swinging = true
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
      @sprite.texture = if @status == :dead
                          @dead_texture
                        elsif @swinging
                          @shield_texture
                        else
                          @alive_texture
                        end

      if @status == :immortal
        window.draw @sprite if @count % 2 == 0
      else
        window.draw @sprite
      end
    end

    def kill
      return if @status != :alive
      @lives -= 1
      @status = :dead
      @dead_music.play
      spawn do
        sleep @kill_time.seconds
        if @lives == 0
          @status = :gameoverman
        else
          @status = :revivable
        end
      end
    end

    def revive
      return if @status != :revivable
      @status = :immortal
      spawn do
        sleep 2.seconds
        @status = :alive
      end
    end

    def add_life
      @lives = @lives + 1
    end

    def respawn
      @status = :alive
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
    @maps = [] of Map
    @count = 0

    def initialize
      @current_level = 0
      @playing = false

      @title_music.open_from_file("./src/ehden/title.ogg") || raise "no music!"
      @title_music.loop = true # make it loop
      @title_music.play

      @maps = [
        Maps::DodgeBullets.new(self),
        Maps::ImpassableObjects.new(self),
        Maps::BreakFences.new(self),
        Maps::FloweyEncounter1.new(self)
      ]
      character.move(@maps[0].start_vector)
    end

    def sword_hit
      @sword_hit ||= SF::Music.from_file("./src/ehden/sword_hit.ogg")
    end

    def sword_miss
      @sword_miss ||= SF::Music.from_file("./src/ehden/sword_miss.ogg")
    end

    def character
      @character ||= Character.new
    end

    def map
      @maps[@current_level]
    end

    def next_map
      @current_level += 1
      character.add_life
      character.move(map.start_vector)
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
      @current_level = 0
      character.respawn
      character.move(map.start_vector)
      map.restart
    end

    def gameoverman
      @playing = false
      @game_music.stop
      @title_music.play
    end

    def render_title(window)
      window.clear @count % 2 == 0 ? SF::Color::Black : SF::Color::Blue
      wb_shader = SF::Shader.from_file("./src/ehden/shaders/wave.vert", "./src/ehden/shaders/blur.frag")
      wb_shader.wave_phase @count
      wb_shader.wave_amplitude 40, 40
      wb_shader.blur_radius 20
      font = SF::Font.from_file("./src/ehden/Cantarell-Regular.otf")
      text = SF::Text.new("EHDEN!!!!", font, 200)
      text.position = {0, 200}
      window.draw text, SF::RenderStates.new(shader: wb_shader)
      instructions = SF::Text.new("Hit bullets at fences to break them!", font, 40)
      instructions.position = {100, 400}
      window.draw instructions
      @count += 1
    end

    def render(window)
      # window.clear SF::Color::Black
      # for debugging
      case character.status
      when :alive
        window.clear SF::Color::Black
      when :dead
        window.clear SF::Color::Red
      when :immortal
        window.clear SF::Color::Blue
      when :revivable
        window.clear SF::Color::Green
      when :gameoverman
        gameoverman
      end
      map.render(window)
      character.render(window)
      map.bullets.each do |bullet|
        if (character.boundaries.contains? bullet.position)
          bullet.killer = true
          character.kill
        end
      end
      (0...character.lives).each do |i|
        heart = heart_shape
        heart.position = {i * 50 + 25, 750}
        window.draw heart
      end
    end

    def heart_shape
      heart = SF::ConvexShape.new
      heart.point_count = 6
      heart[0] = SF.vector2f(10, 10)
      heart[1] = SF.vector2f(15, 0)
      heart[2] = SF.vector2f(20, 10)
      heart[3] = SF.vector2f(10, 25)
      heart[4] = SF.vector2f(0, 10)
      heart[5] = SF.vector2f(5, 0)
      heart.fill_color = SF::Color::Red
      heart
    end

    def move(direction : SF::Vector2f)
      character.revive if character.status == :revivable && direction != SF.vector2f(0, 0)
      return if character.status == :dead

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
        character.move(pos)
        character.facing = direction if direction.x.abs + direction.y.abs > 0
        # go to next map if character walks close enough to the end marker
        next_map if character.boundaries.contains? map.finish_vector
      end
    end

    def swing
      if character.swing
        hit = false
        map.bullets.each_with_index do |bullet, b|
          position = bullet.position
          if character.sword.contains? position
            map.bullets[b] = Bullet.new(
              position,
              (character.pos + {23, 30} - position) / -30
            )
            hit = true
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
