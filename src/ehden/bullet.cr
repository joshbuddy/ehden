class Bullet
  getter position
  property killer = false

  def initialize(@position : SF::Vector2f, @dir : SF::Vector2f)
  end

  def render(window)
    circle = SF::CircleShape.new
    circle.radius = 5
    circle.fill_color = @killer ? SF::Color::Red : SF::Color::White
    @position += @dir
    circle.position = @position
    window.draw circle
  end
end
