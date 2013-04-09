function main() {
	var env;
	await env = FactoryHelper.buildEnv({
		nParty: 3,
		nStarters: 6,
		nBattles: 7,
		allEntriesURL: "entries.csv"
	});
	var result = Predictor.predict(env, new PRNG(0));
	console.log(result);
	document.body.innerHTML = `
		<table>
		<tr><td></td>${Util.iota(env.nBattles).map(i => `<td>${i+1}戦目</td>`).join("")}</tr>
		${
			result.map((r, i) =>
				`<tr>
				<td>${i}件目</td>
				${
					r.enemies.map(enemy =>
						`<td>${enemy.map(x => x.pokemon).join(",")}</td>`).join("")
				}
				</tr>`
			).join("")
		}</table>
	`;
}
window.addEventListener("load", main().then(() => console.log("done"), e => console.log(e)));
