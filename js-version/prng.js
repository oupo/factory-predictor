class PRNG {
	constructor(seed) {
		this.seed = seed;
	}
	rand(n) {
		let prngp = this.dup();
		return [prngp, prngp.randQ(n)];
	}
	randQ(n) {
		this.succ();
		return (this.seed >>> 16) % n;
	}
	succ() {
		const A = 0x41c64e6d, B = 0x6073;
		this.seed = (this._mul(this.seed, A) + B) >>> 0;
	}
	dup() {
		return new PRNG(this.seed);
	}
	_mul(a, b) {
		let a1 = a >>> 16, a2 = a & 0xffff;
		let b1 = b >>> 16, b2 = b & 0xffff;
		return (((a1 * b2 + a2 * b1) << 16) + a2 * b2) >>> 0;
	}
}

