import * from "./predictor.js";
import * from "./util.js";
if (!('console' in window)) window.console = {log: x => x}

var gEnv;
var POKEMON_NAME_TO_ID;
var gPokemonImage;
var ICON_SIZE = 32;

function main() {
	await gEnv = FactoryHelper.buildEnv({
		nParty: 3,
		nStarters: 6,
		nBattles: 7,
		allEntriesURL: "entries.csv?1366277583"
	});
	await POKEMON_NAME_TO_ID = load_pokemon_name_to_id();
	await gPokemonImage = loadImage("icons.png");

	document.body.innerHTML = `
		<h1>factory-predictor Demo</h1>
		<form action="" onsubmit="return false">
		seed: <input type="text" id="seed" value="0">
		<input type="submit" value="実行">
		</form>
		<div id="result"></div>
	`;
	document.querySelector("form").addEventListener("submit", () => {
		exec(Number(document.querySelector("#seed").value));
	}, false);
}

function load_pokemon_name_to_id() {
	var pokemon_names_str;
	await pokemon_names_str = Util.xhr("pokemon-names.txt");
	var pokemon_names = Util.split(pokemon_names_str, "\n");
	var name_to_id = Object.create(null);
	pokemon_names.forEach((name, i) => {
		name_to_id[name] = i + 1;
	});
	return name_to_id;
}

function toPokemonId(entry) {
	return POKEMON_NAME_TO_ID[entry.pokemon];
}

function loadImage(url) {
	var deferred = new Deferred;
	var image = new Image;
	image.src = url;
	image.onload = function() {
		deferred.callback(image);
	};
	image.onerror = function() {
		deferred.errback();
	};
	return deferred.createPromise();
}

function exec(seed) {
	var result = Predictor.predict(gEnv, new PRNG(seed));
	var tree = toTree(gEnv, result);
	//console.log(displayTree(gEnv, tree, 0));
	var canvas = drawTree(tree, 0);
	document.querySelector("#result").innerHTML = "";
	document.querySelector("#result").appendChild(canvas);
}

function drawTree(node, nest) {
	const PAD_X = 10, PAD_Y = 50;
	var [x, children] = node;
	var canvases = children.map(child => scaleCanvas(drawTree(child, nest + 1), 0.6));
	var vertex = drawVertex(x);
	var height = vertex.height + PAD_Y + canvases.map(c => c.height).max()
	var width = canvases.reduce((r,c) => r + c.width, 0) + (canvases.length - 1) * PAD_X;
	width = Math.max(width, vertex.width);
	var ctx = newCanvas(width, height);
	ctx.drawImage(vertex, (width - vertex.width) / 2, 0);
	var x = 0;
	canvases.forEach((child, i) => {
		ctx.beginPath();
		ctx.moveTo(width / 2, vertex.height);
		ctx.lineTo(x + child.width / 2, vertex.height + PAD_Y);
		ctx.stroke();
		ctx.drawImage(child, x, vertex.height + PAD_Y);
		x += child.width + PAD_X;
	});
	return ctx.canvas;
}

function scaleCanvas(canvas, scale) {
	var w = canvas.width * scale, h = canvas.height * scale;
	var ctx = newCanvas(w, h);
	ctx.drawImage(canvas, 0, 0, canvas.width, canvas.height, 0, 0, w, h);
	return ctx.canvas;
}

function drawVertex(entries) {
	var s = 32;
	var [w, h] = [100, 32];
	var ctx = newCanvas(w, h);
	ctx.fillStyle = "#F7E6A3";
	ctx.fillRect(0, 0, w, h);
	var startX = (w - s * entries.length) / 2;
	var y = (h - s) / 2;
	entries.forEach((entry, i) => {
		var id = toPokemonId(entry);
		var x = startX + s * i;
		ctx.drawImage(gPokemonImage, s * (id - 1), 0, s, s, x, y, s, s);
	});
	return ctx.canvas;
}

function newCanvas(w, h) {
	var canvas = document.createElement("canvas");
	canvas.width = w, canvas.height = h;
	return canvas.getContext("2d");
}

function displayTree(env, node, nest) {
	var indent = Util.str_repeat("--", nest);
	var prefix = `${indent} ${nest + 1}. `;
	var out = "";
	var [x, children] = node;
	out += `${prefix}${x.map(e => e.pokemon).join(" ")}\n`;
	for (var child of children) {
		out += displayTree(env, child, nest + 1);
	}
	return out;
}

function toTree(env, results) {
	var nodes = toTree0(env, results, 0);
	if (nodes.length != 1) throw "nodes.length must == 1";
	return nodes[0];
}

function toTree0(env, results, i) {
	function toKey(r) {
		return r.enemies[i];
	}
	
	if (i == env.nBattles - 1) {
		return results.map(x => [toKey(x), []]);
	} else {
		return groupBy(results, toKey).map(([key, elems]) => [key, toTree0(env, elems, i + 1)]);
	}
}

function groupBy(array, toKey) {
	var result = [];
	for (var x of array) {
		var key = toKey(x);
		var found = result.find(([k, elems]) => equals(k, key));
		
		if (!found) {
			result.push([key, [x]]);
		} else {
			var [k, elems] = found;
			elems.push(x);
		}
	}
	return result;
}

function equals(a, b) {
	if (Array.isArray(a) && Array.isArray(b)) {
		return a.length === b.length && a.every((x, i) => equals(a[i], b[i]));
	} else {
		return a === b;
	}
}

window.addEventListener("load", () => {
	main().then(() => console.log("done"), e => console.log(e));
});
