module Ehden
  abstract class Enemy
    @running = false

    abstract def start(app : App)

    def stop
      @running = false
    end
  end
end
