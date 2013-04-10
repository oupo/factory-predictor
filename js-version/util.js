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

Object.defineProperty(Array.prototype, "include", {
	value: function(x) {
		return this.indexOf(x) >= 0;
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "clone", {
	value: function() {
		return this.slice(0);
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "count", {
	value: function(predicate) {
		var num = 0;
		for (var x of this) {
			if (predicate(x)) num += 1;
		}
		return num;
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "diff", {
	value: function(other) {
		return this.filter(x => !other.include(x));
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "cap", {
	value: function(other) {
		return this.filter(x => other.include(x));
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "sortBy", {
	value: function(func) {
		var keys = this.map(func);
		return Util.iota(this.length).sort((a, b) => keys[a] - keys[b]).map(i => this[i]);
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "minBy", {
	value: function(keyOf) {
		var min = null;
		for (var x of this) {
			if (min == null || keyOf(x) < keyOf(min)) min = x;
		}
		return min;
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "maxBy", {
	value: function(keyOf) {
		var max = null;
		for (var x of this) {
			if (max == null || keyOf(max) < keyOf(x)) max = x;
		}
		return max;
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "max", {
	value: function() {
		return this.maxBy(x => x);
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "findIndex", {
	value: function(func) {
		for (var i = 0; i < this.length; i ++) {
			if (func(this[i])) return i;
		}
		return null;
	},
	configurable: true,
	enumerable: false,
	writable: true
});

Object.defineProperty(Array.prototype, "find", {
	value: function(func) {
		for (var x of this) {
			if (func(x)) return x;
		}
		return null;
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

Object.defineProperty(Array.prototype, "isEmpty", {
	get: function() {
		return this.length == 0;
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
}
