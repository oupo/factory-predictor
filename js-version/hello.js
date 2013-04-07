let allEntries = [
	new Entry(0, 0, 0),
	new Entry(1, 1, 1),
	new Entry(2, 2, 2),
	new Entry(3, 3, 3),
	new Entry(4, 4, 4),
];
let env = new Env({nParty: 3, nStarters: 6, nBattles: 4, allEntries: allEntries});
let prng = new PRNG(0);
console.log(FactoryHelper.choose_entryQ(env, prng));
console.log(FactoryHelper.choose_entryQ(env, prng));
console.log(FactoryHelper.choose_entryQ(env, prng));


