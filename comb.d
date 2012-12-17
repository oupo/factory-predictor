module comb;
import std.range;
import std.array;
import std.stdio;

class Combination(T) {
	T[] items;
	int n;
	this(T[] items, int n) {
		this.items = items;
		this.n = n;
	}
	int opApply(int delegate(T[]) dg)
	{
		if (n == 0) {
			return dg([]);
		}
		foreach (i; 0..items.length) {
			foreach (x; combination(items[i+1..$], n-1)) {
				int ret = dg(items[i] ~ x);
				if (ret) return ret;
			}
		}
		return 0;
	}
}

Combination!(T) combination(T)(T[] items, int n) {
	return new Combination!(T)(items, n);
}
