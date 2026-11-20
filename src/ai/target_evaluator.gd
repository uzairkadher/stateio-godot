class_name TargetEvaluator
extends RefCounted
## Travel-time-aware utility scoring for Bot AI (M6).
## Projects target population at arrival ETA and scores Defend, Neutral Expand,
## Weak-Enemy Attack, and Frontline Reinforce candidates.

const BASE_SPEED_ESTIMATE := 3.5

static func compute_incoming_threats(snapshot: SimSnapshot, bot_owner: int) -> Dictionary:
	# building_id -> {"enemy": int, "friendly": int}
	var map: Dictionary = {}
	for g in snapshot.troop_groups:
		var tid: String = str(g.get("target_id", ""))
		if tid.is_empty():
			continue
		if not map.has(tid):
			map[tid] = {"enemy": 0, "friendly": 0}
		var amt: int = int(g.get("amount", 0))
		if int(g.get("owner_id", 0)) == bot_owner:
			map[tid]["friendly"] = int(map[tid]["friendly"]) + amt
		else:
			map[tid]["enemy"] = int(map[tid]["enemy"]) + amt
	return map

static func evaluate_best_action(
	snapshot: SimSnapshot,
	bot_owner: int,
	cfg: BotConfig,
	force_break_idle: bool = false
) -> Dictionary:
	var owned: Array = []
	for bid in snapshot.building_order:
		var b: Dictionary = snapshot.buildings[bid]
		if int(b.get("owner_id", 0)) == bot_owner:
			owned.append(b)
	if owned.is_empty():
		return {}

	var threats: Dictionary = compute_incoming_threats(snapshot, bot_owner)
	var best_score: float = -INF
	var best_plan: Dictionary = {}

	for src in owned:
		var src_id: String = str(src["id"])
		var src_pop: int = int(src["population"])
		var src_threat: int = int(threats.get(src_id, {}).get("enemy", 0))
		var safe_keep: int = cfg.min_garrison_keep + src_threat
		var available: int = src_pop - safe_keep
		if force_break_idle:
			available = maxi(available, src_pop - 2)
		if available < 2:
			continue

		var src_pos: Vector2 = src["position"]
		for tid in snapshot.building_order:
			if tid == src_id:
				continue
			var dst: Dictionary = snapshot.buildings[tid]
			var dst_owner: int = int(dst["owner_id"])
			var dst_pop: int = int(dst["population"])
			var dst_pos: Vector2 = dst["position"]
			var dist: float = maxf(0.5, src_pos.distance_to(dst_pos))
			var eta: float = dist / BASE_SPEED_ESTIMATE
			var dst_threat: int = int(threats.get(tid, {}).get("enemy", 0))
			var dst_friendly: int = int(threats.get(tid, {}).get("friendly", 0))
			var shield_hp: float = float(dst.get("shield_hp", 0.0))

			var score: float = -INF
			var ratio: float = cfg.send_ratio_attack
			var intent: String = "attack"

			if dst_owner == bot_owner:
				# Defend threatened ally or reinforce frontline
				if dst_threat > dst_pop + dst_friendly:
					var deficit: int = dst_threat - (dst_pop + dst_friendly)
					score = (50.0 + float(deficit) * 2.5) * cfg.defense_weight / (1.0 + eta * 0.4)
					ratio = cfg.send_ratio_defend
					intent = "defend"
				elif src_pop >= int(src["population_cap"]) - 4 and dst_pop < int(dst["population_cap"]) - 10:
					score = 18.0 * cfg.reinforce_weight / (1.0 + eta * 0.5)
					ratio = 0.5
					intent = "reinforce"
			elif dst_owner == GameEnums.OwnerId.NEUTRAL:
				var send_est: int = int(floor(float(src_pop) * cfg.send_ratio_expand))
				var effective_cost: float = float(dst_pop) + shield_hp - float(dst_friendly)
				var surplus: float = float(send_est) - effective_cost
				if surplus >= float(cfg.min_attack_surplus) or (force_break_idle and surplus >= 1.0):
					var mech_bonus: float = 12.0 if int(dst.get("mechanic_type", 0)) != 0 else 0.0
					score = (32.0 + surplus * 1.4 + mech_bonus) * cfg.expand_weight / (1.0 + eta * 0.35)
					ratio = cfg.send_ratio_expand
					intent = "expand"
			else:
				# Enemy building: project growth over ETA
				var projected_enemy: float = float(dst_pop) + eta * float(dst.get("base_spawn_rate", 1.0)) + shield_hp - float(dst_friendly)
				var send_est: int = int(floor(float(src_pop) * cfg.send_ratio_attack))
				var surplus: float = float(send_est) - projected_enemy
				if surplus >= float(cfg.min_attack_surplus) or (force_break_idle and surplus >= 1.0):
					score = (38.0 + surplus * 1.6) * cfg.aggression_weight / (1.0 + eta * 0.35)
					ratio = cfg.send_ratio_attack
					intent = "attack"

			if score > best_score:
				best_score = score
				best_plan = {
					"source_id": src_id,
					"target_id": tid,
					"send_ratio": ratio,
					"score": score,
					"intent": intent,
				}

	return best_plan
