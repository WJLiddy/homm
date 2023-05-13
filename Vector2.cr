struct Vector2
  getter x, y

  def initialize(@x : Int32, @y : Int32)
  end

  # Binary operator. Returns *other* added to `self`.
  def +(other : self) : self
    Vector2.new(x + other.x, y + other.y)
  end
end