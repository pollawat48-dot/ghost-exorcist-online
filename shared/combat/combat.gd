extends RefCounted
## สูตรการต่อสู้ ใช้ร่วมกันทั้ง client และ zone server

## ตัวคูณดาเมจ: ธาตุการโจมตี -> ธาตุเป้าหมาย
## ตีธรรมดาใส่ผีวิญญาณได้ไม่ค่อยเข้า ต้องใช้พลังศักดิ์สิทธิ์
const ELEMENT_MOD := {
	"neutral": {"none": 1.0, "spirit": 0.7, "curse": 1.0},
	"holy": {"none": 1.0, "spirit": 1.75, "curse": 1.5},
}


static func element_mod(attack_element: String, target_element: String) -> float:
	var row: Dictionary = ELEMENT_MOD.get(attack_element, {})
	return row.get(target_element, 1.0)


static func damage(atk: int, def: int, attack_element: String, target_element: String, rng: RandomNumberGenerator, power: float = 1.0) -> int:
	var raw := float(atk) * power * rng.randf_range(0.9, 1.1) - float(def)
	raw *= element_mod(attack_element, target_element)
	return maxi(1, int(round(raw)))
