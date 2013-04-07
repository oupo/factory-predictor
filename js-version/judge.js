class Judge {
	constructor(env, result) {
		this.env = env;
		this.shop = Util.range(0, nBattles).map(i => {
			if (i == 0) {
				return result.starters.map(x => x.item);
			} else {
				return result.enemies[i-1].map(x => x.item);
			}
		});
		this.gate = (0..nBattles).map(i =>
			if (i >= 2) {
				return result.skipped[i-1].map(&:item)
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
		let assigner = new Assigner.new(this.env);
		for (let j of Util.range(2, nBattles)) {
			for (let item of this.gate[i]) {
				j = Util.range(0, i-2).filter(j => this.shop[j].include(item) }).max();
				if (j == nil) return null;
				work = new Work(item, j + 2, i);
				if (!assigner.assignable(work)) return null;
				assigner.assign(work);
			}
		}
		return assigner.assigned;
	}

	judge0(schedule) {
		let player = nil;
		for (let i of range(2, nBattles)) {
			// gate iの手前のshop
			let sh = this.shop[i-2];
			if (i == 2) {
				let items = schedule.filter(w => w.head == i).map(w => w.item);
				player = [...items, ...(sh.diff(items).sortBy(item => -this.caught(item, i))].slice(nParty);
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
			if (!(player.cap(this.shop[i]).isEmpty) {
				return false;
			}
		}
		return true;
	}

	caught(item, pos) {
		return range(pos, nBattles).find(i => this.shop[i].include(item)) || nBattles+1;
	}
}

# gate iの一つ手前でアイテムaを得て少なくともgate jまで保持し続けるという仕事を
# Work.new(a, i, j)で表す
Work = Struct.new(:item, :head, :tail)
Work.class_eval do
	def range() head..tail end
end

# 仕事の割り当て
class Assigner
	initialize(env) {
		@env = env
		@assigned = []
	}

	attr_reader :env
	include EnvMixin 

	attr_reader :assigned
	
	assign(work) {
		return if exist_similar_longer_work(work)
		assigned = pick_similar_work(work)
		if assignable0(assigned, work)
			@assigned = assigned + [work]
		else
			raise "impossible"
		}
	}
	
	assignable?(work) {
		return true if exist_similar_longer_work(work)
		assigned = pick_similar_work(work)
		assignable0(assigned, work)
	}

	private
	assignable0(assigned, work) {
		work.range.all? {|i| covered_num(assigned, i) < nParty }\
			and startable_num(assigned, work.head) >= 1
	}

	exist_similar_longer_work(work) {
		i = find_similar_work(work)
		i and work.tail <= @assigned[i].tail
	}

	find_similar_work(work) {
		@assigned.find_index {|w| [w.item, w.head] == [work.item, work.head] }
	}

	pick_similar_work(work) {
		i = find_similar_work(work)
		i ? @assigned.dup.tap {|x| x.delete_at(i) } : @assigned
	}

	startable_num(assigned, pos) {
		max = pos == 2 ? nParty : 1
		max - assigned.count {|work| work.head == pos }
	}

	covered_num(assigned, pos) {
		assigned.count {|work| work.range.include?(pos) }
	}
}

