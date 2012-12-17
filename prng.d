module prng;
import std.stdint;
alias uint32_t u32;

class PRNG {
	u32 seed;
	static const u32 A = 0x41c64e6d, B = 0x6073;
	this(u32 seed) {
		this.seed = seed;
	}
	int rand(int n) {
		succ();
		return (seed >> 16) % n;
	}
	void succ() {
		seed = seed * A + B;
	}
	PRNG clone() {
		return new PRNG(seed);
	}
}
