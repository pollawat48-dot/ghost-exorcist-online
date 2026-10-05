extends RefCounted
## ข้อมูลผีทั้งหมด ใช้ร่วมกันทั้ง client และ zone server

const GHOSTS := {
	"krasue_noi": {
		"name": "ผีกระสือน้อย",
		"level": 2,
		"hp": 40,
		"atk": 6,
		"def": 1,
		"element": "spirit",
		"exp": 12,
		"speed": 55.0,
		"attack_range": 28.0,
		"attack_interval": 1.6,
		"aggressive": false,
		"color": Color(0.95, 0.35, 0.45),
		"drops": [
			{"item": "spirit_shard", "chance": 0.5},
			{"item": "red_thread", "chance": 0.3},
			{"item": "soul_krasue", "chance": 0.02},
		],
	},
	"phi_takiang": {
		"name": "ผีตะเกียง",
		"level": 4,
		"hp": 70,
		"atk": 10,
		"def": 3,
		"element": "curse",
		"exp": 25,
		"speed": 45.0,
		"attack_range": 30.0,
		"attack_interval": 1.8,
		"aggressive": true,
		"color": Color(1.0, 0.7, 0.2),
		"drops": [
			{"item": "lantern_oil", "chance": 0.5},
			{"item": "herb_potion", "chance": 0.15},
			{"item": "soul_takiang", "chance": 0.02},
		],
	},
}
