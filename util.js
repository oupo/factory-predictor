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
function defineMethod(object, name, func) {
	Object.defineProperty(object, name, {
		value: func,
		configurable: true,
		enumerable: false,
		writable: true
	});
}
defineMethod(Array.prototype, "include", function (x) {
	return this.indexOf(x) >= 0;
});

defineMethod(Array.prototype, "clone", function () {
	return this.slice(0);
});

defineMethod(Array.prototype, "count", function (predicate) {
	var num = 0;
	for (var x of this) {
		if (predicate(x)) num += 1;
	}
	return num;
});

defineMethod(Array.prototype, "diff", function (other) {
	return this.filter(x => !other.include(x));
});

defineMethod(Array.prototype, "cap", function (other) {
	return this.filter(x => other.include(x));
});

defineMethod(Array.prototype, "sortBy", function (func) {
	var keys = this.map(func);
	return Util.iota(this.length).sort((a, b) => keys[a] - keys[b]).map(i => this[i]);
});

defineMethod(Array.prototype, "minBy", function (keyOf) {
	var min = null;
	for (var x of this) {
		if (min == null || keyOf(x) < keyOf(min)) min = x;
	}
	return min;
});

defineMethod(Array.prototype, "maxBy", function (keyOf) {
	var max = null;
	for (var x of this) {
		if (max == null || keyOf(max) < keyOf(x)) max = x;
	}
	return max;
});

defineMethod(Array.prototype, "max", function () {
	return this.maxBy(x => x);
});

defineMethod(Array.prototype, "findIndex", function (func) {
	for (var i = 0; i < this.length; i ++) {
		if (func(this[i])) return i;
	}
	return null;
});

defineMethod(Array.prototype, "find", function (func) {
	for (var x of this) {
		if (func(x)) return x;
	}
	return null;
});

defineMethod(Array.prototype, "isEmpty", function() {
	return this.length == 0;
});

Object.defineProperty(Array.prototype, "last", {
	get: function() {
		return this[this.length - 1];
	},
	enumerable: false,
});

export class Util {
	static split(str, sep) {
		var array = str.split(sep);
		if (array.last == "") array.pop();
		return array;
	}
	
	static range(start, end) {
		var array = [];
		for (var i = start; i <= end; i ++) {
			array.push(i);
		}
		return array;
	}
	
	static iota(n) {
		return this.range(0, n-1);
	}
	
	static xhr(url) {
		var xhr = new XMLHttpRequest();
		var deferred = new Deferred;
		xhr.onload = function() {
			if (xhr.status == 200 || xhr.status == 0) {
				deferred.callback(xhr.responseText);
			} else {
				deferred.errback();
			}
		};
		xhr.onerror = function() {
			errback();
		};
		xhr.open("GET", url, true);
		xhr.send();
		return deferred;
	}

	static hex(n, prec=8) {
		var s = n.toString(16);
		return "0x" + (this.str_repeat("0", prec - s.length) + s);
	}

	static dec(n, prec) {
		var s = String(n);
		return this.str_repeat("0", prec - s.length) + s;
	}

	static str_repeat(s, n) {
		var r = "";
		for (var i = 0; i < n; i ++) {
			r += s;
		}
		return r;
	}
}
