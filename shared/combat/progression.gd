extends RefCounted
## เลเวลและสเตตัสของผู้เล่น ใช้ร่วมกันทั้ง client และ zone server

const MAX_LEVEL := 99


static func exp_to_next(level: int) -> int:
	return int(round(20.0 * pow(level, 1.6)))


static func stats_for_level(level: int) -> Dictionary:
	return {
		"max_hp": 80 + level * 15,
		"max_sp": 20 + level * 5,
		"atk": 8 + level * 2,
		"def": level,
	}


## เพิ่ม EXP ให้ state ({"level", "exp"}) แล้วคืนจำนวนเลเวลที่อัป
static func add_exp(state: Dictionary, amount: int) -> int:
	var gained := 0
	state["exp"] += amount
	while state["level"] < MAX_LEVEL and state["exp"] >= exp_to_next(state["level"]):
		state["exp"] -= exp_to_next(state["level"])
		state["level"] += 1
		gained += 1
	return gained
