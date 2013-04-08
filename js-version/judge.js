class Judge {
	constructor(env, result) {
		this.env = env;
		this.shop = Util.range(0, this.env.nBattles).map(i => {
			if (i == 0) {
				return result.starters.map(x => x.item);
			} else {
				return result.enemies[i-1].map(x => x.item);
			}
		});
		this.gate = Util.range(0, this.env.nBattles).map(i => {
			if (i >= 2) {
				return result.skipped[i-1].map(x => x.item);
			}
		});
	}

	static judge(env, result) {
		return new this(env, result).judge();
	}

	judge() {
		let schedule = this.assign_works();
		return schedule != null && this.judge0(schedule);
	}
	
	assign_works() {
		let assigner = new Assigner(this.env);
		for (let i of Util.range(2, this.env.nBattles)) {
			for (let item of this.gate[i]) {
				let j = Util.range(0, i-2).filter(j => this.shop[j].include(item)).max();
				if (j == null) return null;
				let work = new Work(item, j + 2, i);
				if (!assigner.assignable(work)) return null;
				assigner.assign(work);
			}
		}
		return assigner.assigned;
	}

	judge0(schedule) {
		let player = null;
		for (let i of Util.range(2, this.env.nBattles)) {
			// gate iの手前のshop
			let sh = this.shop[i-2];
			if (i == 2) {
				let items = schedule.filter(w => w.head == i).map(w => w.item);
				player = [...items, ...(sh.diff(items).sortBy(item => -this.caught(item, i)))].slice(0, this.env.nParty);
			} else {
				let current_works = schedule.filter(w => w.range.include(i) && w.head != i);
				let player_desertable = player.diff(current_works.map(w => w.item));
				let a = player_desertable.minBy(item => this.caught(item, i));
				let work = schedule.find(w => w.head == i);
				if (work) {
					player = [...player.diff([a]), work.item];
				} else {
					let b = sh.maxBy(item => this.caught(item, i));
					if (this.caught(a, i) < this.caught(b, i)) {
						player = [...player.diff([a]), b];
					}
				}
			}

			// gate i
			if (!(player.cap(this.shop[i]).isEmpty)) {
				return false;
			}
		}
		return true;
	}

	caught(item, pos) {
		let i = Util.range(pos, this.env.nBattles).find(i => this.shop[i].include(item));
		return (i != null) ? i : this.env.nBattles+1;
	}
}

// gate iの一つ手前でアイテムaを得て少なくともgate jまで保持し続けるという仕事を
// Work.new(a, i, j)で表す
class Work {
	constructor(item, head, tail) {
		this.item = item;
		this.head = head;
		this.tail = tail;
		this.range = Util.range(head, tail);
	}
}

// 仕事の割り当て
class Assigner {
	constructor(env) {
		this.env = env;
		this.assigned = [];
	}

	assign(work) {
		if (this.exist_similar_longer_work(work)) return;
		let assigned = this.pick_similar_work(work);
		if (this.assignable0(assigned, work)) {
			this.assigned = [...assigned, work];
		} else {
			throw "impossible";
		}
	}
	
	assignable(work) {
		if (this.exist_similar_longer_work(work)) {
			return true;
		}
		let assigned = this.pick_similar_work(work);
		return this.assignable0(assigned, work)
	}

	assignable0(assigned, work) {
		return work.range.every(i => this.covered_num(assigned, i) < this.env.nParty ) &&
			this.startable_num(assigned, work.head) >= 1;
	}

	exist_similar_longer_work(work) {
		let i = this.find_similar_work(work);
		return i != null &&  work.tail <= this.assigned[i].tail;
	}

	find_similar_work(work) {
		return this.assigned.findIndex(w => w.item == work.item && w.head == work.head);
	}

	pick_similar_work(work) {
		let i = this.find_similar_work(work);
		if (i != null) {
			var assigned = this.assigned.clone();
			assigned.splice(i, 1);
			return assigned;
		} else {
			return this.assigned;
		}
	}

	startable_num(assigned, pos) {
		let max = pos == 2 ? this.env.nParty : 1;
		return max - assigned.count(work => work.head == pos);
	}

	covered_num(assigned, pos) {
		return assigned.count(work => work.range.include(pos));
	}
}

