class PRNG
  def initialize(seed)
    @seed = seed
  end

  attr_reader :seed

  def rand(n)
    succ!
    (@seed >> 16) % n
  end
  
  def succ!
    @seed = (@seed * 0x41c64e6d + 0x6073) & 0xffffffff
  end
end
