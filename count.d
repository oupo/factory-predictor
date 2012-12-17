import std.stdio;
import std.range;
import std.array;
import std.algorithm;
import prng;
import comb;

const NUM_ENTRIES = 100;
const NUM_STARTERS = 6;
const NUM_PARTY = 3;

void main(string[] args) {
	int[NUM_STARTERS] starters = array(iota(0,NUM_STARTERS));
	auto prng = new PRNG(0);
	writefln("%d", get_comb_naive(starters, prng));
}

int get_comb_naive(int[] starters, PRNG prng) {
	bool[immutable int[]] set;
	foreach (playerParty; starters.combination(NUM_PARTY)) {
		auto p = prng.clone();
		auto enemyParty = choiceEnemyParty(playerParty, p);
		set[cast(immutable)enemyParty.dup] = true;
	}
	writeln(set);
	return set.length;
}

int[] choiceEnemyParty(int[] playerParty, PRNG p) {
	int[] result;
	while (result.length < NUM_PARTY) {
		int x = p.rand(NUM_ENTRIES);
		if (!result.canFind(x) && !playerParty.canFind(x)) {
			result ~= x;
		}
	}
	return result;
}
