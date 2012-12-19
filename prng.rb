PRNG = Struct.new(:seed) # ==, eql?, hashのためにStructから作る

PRNG.class_eval do
  def rand(n)
    p = dup()
    [p, p.rand!(n)]
  end

  def rand!(n)
    succ!
    (seed >> 16) % n
  end
  
  def succ!
    self.seed = (seed * 0x41c64e6d + 0x6073) & 0xffffffff
  end
end
