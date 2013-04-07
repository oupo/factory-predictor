var fs = require("fs");


var csvString = fs.readFileSync("entries.csv", "utf8");
let allEntries = FactoryHelper.parseAllEntries(csvString);

let env = new Env({nParty: 3, nStarters: 6, nBattles: 4, allEntries: allEntries});
let result = OneEnemyPredictor.predict(env, new PRNG(0), [], allEntries);
console.log(result.length);