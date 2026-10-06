extends RefCounted
## สูตรหลอมแร่ที่ร้านหลอม: ใช้เหรียญ + แร่หลายชนิด หินขั้นสูงใช้แร่หายากกว่า
## ตอนนี้หลอมได้แค่หินตี+ (ไว้ตีบวกของสวมใส่) ภายหลังเพิ่มสูตรอื่นได้ที่นี่

const RECIPES := {
	"hin_ti_1": {"coins": 50, "ores": {"ore_zinc": 5, "ore_iron": 1}},
	"hin_ti_2": {"coins": 400, "ores": {"ore_zinc": 8, "ore_iron": 5, "ore_gold": 1}},
	"hin_ti_3": {"coins": 2500, "ores": {"ore_iron": 10, "ore_gold": 5, "ore_diamond": 1}},
}
const ORDER := ["hin_ti_1", "hin_ti_2", "hin_ti_3"]


## หลอมได้กี่ชิ้นจากของที่มี
static func max_craft(id: String, inventory: Dictionary, coins: int) -> int:
	var r: Dictionary = RECIPES[id]
	var n: int = coins / maxi(1, r["coins"])
	for ore in r["ores"]:
		n = mini(n, inventory.get(ore, 0) / r["ores"][ore])
	return n
