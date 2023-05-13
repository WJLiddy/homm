class HommRandom
  def initialize(seed)
    @random = Random.new(seed, sequence = 0_u64)
  end
  # random between to integers exclusive
  def rint(lo : Int32, hi : Int32)
    return @random.rand(lo..hi-1)
  end
end