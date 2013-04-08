def sys(cmd) system(cmd) or abort end
sys "traceur --experimental --out compiled.js util.js prng.js factory-helper.js rough.js judge.js hello.js"
sys "type traceur.js > compiled2.js"
sys "type compiled.js >> compiled2.js"
sys "node compiled2.js"
