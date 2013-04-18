const A = 0x41c64e6d, B = 0x6073;

export class PRNG {
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
		this.seed = u32(mul(this.seed, A) + B);
	}
	stepQ(n) {
		let [a, b] = make_const(n);
		this.seed = u32(mul(this.seed, a) + b);
	}
	dup() {
		return new PRNG(this.seed);
	}
}

function make_const(n) {
	var a = A, b = B;
	var c = 1, d = 0;
	while (n) {
		if (n & 1) {
			d = u32(mul(d, a) + b);
			c = mul(c, a);
		}
		b = u32(mul(b, a) + b);
		a = mul(a, a);
		n >>>= 1;
	}
	return [c, d];
}

function mul(a, b) {
	let a1 = a >>> 16, a2 = a & 0xffff;
	let b1 = b >>> 16, b2 = b & 0xffff;
	return u32(((a1 * b2 + a2 * b1) << 16) + a2 * b2);
}

function u32(x) { return x >>> 0; }
