module Ehden
  class Shooter < Enemy
    def initialize(@pos : SF::Vector2f, @rate : Int32, @dir : SF::Vector2f)
    end

    def start(app)
      @running = true
      spawn do
        loop do
          sleep @rate.milliseconds
          break unless @running
          app.add_bullet(@pos, @dir) if app.playing?
        end
      end
    end
  end
end
