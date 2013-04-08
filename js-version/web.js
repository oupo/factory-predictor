window.addEventListener("load", () => {
	var env;
	await env = FactoryHelper.buildEnv({
		nParty: 3,
		nStarters: 6,
		nBattles: 4,
		allEntriesURL: "entries.csv"
	});
	alert(uneval(env));
});
