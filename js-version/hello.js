console.log(["a,5", "b,2", "c,3"].sortBy(x => Number(x.split(",")[1])))
throw "";

var fs = require("fs");

var csvString = fs.readFileSync("entries.csv", "utf8");
let allEntries = FactoryHelper.parseAllEntries(csvString);

let env = new Env({nParty: 3, nStarters: 6, nBattles: 4, allEntries: allEntries});
let result = RoughPredictor.predict(env, new PRNG(0)).map(x => x.enemies.map(y => y.map(z => z.id)));
console.log(result);