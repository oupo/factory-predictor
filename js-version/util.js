Object.defineProperty(Array.prototype, "flatten", {
	value: function() {
		var ret = [];
		for (var i = 0; i < this.length; i ++) {
			ret.push(...this[i]);
		}
		return ret;
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "last", {
	get: function() {
		return this[this.length - 1];
	},
	enumerable: false,
});

class Util {
	static split(str, sep) {
		var array = str.split(sep);
		if (array.last == "") array.pop();
		return array;
	}
}
