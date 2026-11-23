class_name PixSprite
extends RefCounted
## Hand-placed pixel sprites drawn from ASCII rows. '.' = transparent. Authored facing RIGHT.

const SPUD := {
	"pal": {"o": "2a1a0c", "l": "c9a46c", "b": "a98350", "d": "7a5a30", "s": "5e4423", "k": "140a05", "w": "f0e8d0", "p": "e8908a", "m": "7a2020", "G": "4a9a2a", "H": "8ad04a"},
	"rows": [
		"......oGHo......",
		"....oooGoooo....",
		".ooollllllllloo.",
		".ollllllllllbbo.",
		"ollllllllllbbbbo",
		"olllewllllewlbbo",
		"ollleelllleelbbo",
		"ollppllllllppbbo",
		"ollllllmmmllbbbo",
		"olllllllmllbbbbo",
		"ollllbbbbbbbbbbo",
		"olllbbbsbbbbbbbo",
		".olbbbbbbbbbsbo.",
		".obbbbsbbbbbbdo.",
		".oddbbbbbbbbddo.",
		"..ooddddddddoo..",
		".....oooooo.....",
	],
}

const MINIONS := {
	"ember_imp": {"pal": {"o": "2a0806", "r": "d83a22", "d": "8a2014", "h": "3a1008", "y": "ffe040", "w": "f4ecd0"}, "rows": [
		"h..........h",
		"hh.oooooo.hh",
		".hoorrrroohh",
		"..orrrrrrro.",
		"..oryyrryro.",
		"..orrrrrrro.",
		"..orwrwrwro.",
		"...orrrrro..",
		"..oodrrdoo..",
		".od.oddo.do.",
		".o..o..o..o.",
	]},
	"ash_moth": {"pal": {"o": "1a1614", "g": "9a908a", "G": "6a625e", "r": "ff5a20"}, "rows": [
		".gg......gg.",
		"gGGg.oo.gGGg",
		"gGGGgoogGGGg",
		".gGGgorogGg.",
		"..gg.oo.gg..",
		".....oo.....",
	]},
	"cinder_rat": {"pal": {"o": "1e1008", "d": "5a3a2a", "l": "7a5240", "r": "ff6a1a", "t": "c88a70", "w": "f0e8d0"}, "rows": [
		"..........oo...",
		"........oooldo.",
		".ooo..oolddddor",
		"otddooddddddddo",
		".oddddddddsddwo",
		"..oddddddddddo.",
		"...oo.oo..oo.oo",
		"...o..o...o..o.",
	]},
	"magma_blob": {"pal": {"o": "2a0a04", "r": "f06a1c", "d": "b0400e", "y": "ffd040", "k": "140400"}, "rows": [
		"....oooooo....",
		"..ooorrrrooo..",
		".orrrrrrrrrro.",
		".orrkkrrkkrro.",
		"orrrkykrkykrro",
		"orrrrrrrrrrrro",
		"orrdrryyrrdrro",
		"ordddrrrrdddro",
		".oodddddddddo.",
		"..oooooooooo..",
	]},
	"bone_bat": {"pal": {"o": "1a1410", "w": "d8d0c0", "g": "a89e8c", "r": "ff3010"}, "rows": [
		"o..........o",
		"ow........wo",
		"owg..oo..gwo",
		".owgowwogwo.",
		".owwwrwrwwo.",
		"..owwwwwwo..",
		"...ogwwgo...",
		"....oooo....",
	]},
	"soot_sprite": {"pal": {"o": "0a0808", "k": "2a2420", "w": "ffffff", "r": "ff5020"}, "rows": [
		"o..o.oo.o..o",
		".o.kkkkkk.o.",
		"..kkkkkkkk..",
		"o.kkwkkwkk.o",
		"..kkrkkrkk..",
		"o.kkkkkkkk.o",
		"..kkkkkkkk..",
		".o.kkkkkk.o.",
		"o..o.oo.o..o",
	]},
	"hell_beetle": {"pal": {"o": "120a08", "d": "4a1e14", "l": "7a3424", "h": "2a1008", "r": "ff5a14", "y": "d8a020"}, "rows": [
		"..........oo....",
		"....ooooooohho..",
		"..ooldlllddooho.",
		".oldlldllldlloro",
		"oldlldddlddlldoo",
		"odddddddddddddyo",
		"oddhddhddhdddoo.",
		".oooooooooooooo.",
		"..oh.oh..oh.oh..",
		"..o...o...o..o..",
	]},
	"brimstone_wisp": {"pal": {"o": "3a1004", "y": "ffd040", "r": "ff6a1a", "w": "fff8d0", "k": "140400"}, "rows": [
		".....oo.....",
		"....orro....",
		"...orrrro...",
		"..orryyrro..",
		".orrywwyrro.",
		".orywkwkyro.",
		".orrywwyrro.",
		"..orryyrro..",
		"...orrrro...",
		"....oroo....",
		".....oo.....",
	]},
	"halo_sprite": {"pal": {"o": "3a2a10", "y": "ffd848", "w": "f4f0e8", "g": "b8b4ac", "k": "202030"}, "rows": [
		"...yyyyyy...",
		"..y......y..",
		"...yyyyyy...",
		"..oooooooo..",
		".owwwwwwwwo.",
		".owkkwwkkwo.",
		".owkkwwkkwo.",
		".owwwwwwwwo.",
		"gowwwooowwog",
		"ggowwwwwwogg",
		".ggoooooogg.",
	]},
	"feather_wisp": {"pal": {"o": "30304a", "w": "e8e8f8", "g": "a8a8c8", "k": "202038"}, "rows": [
		"..........oo",
		"........oowo",
		"......oowwgo",
		"....oowwwgo.",
		"..oowwwwgo..",
		".owwwwwggo..",
		"owkwwwggo...",
		".oggggoo....",
		"..oooo......",
	]},
	"choir_lamb": {"pal": {"o": "2a2418", "w": "f0eee4", "g": "c8c4b4", "k": "181410", "y": "ffd848", "h": "e8e0c8"}, "rows": [
		"...oooooo.....",
		"..owwwwwwo.oo.",
		".owwgwwgwwookko",
		"owwwwwwwwwhhkko",
		"owgwwwwwgwhhhoo",
		"owwwwwwwwwhooo.",
		".owwgwwwwwoo...",
		"..oooooooo.....",
		"..ok.ok..ok.ok.",
		"..o..o...o..o..",
	]},
	"bell_cherub": {"pal": {"o": "3a2a0c", "y": "e8b830", "Y": "a07818", "w": "f8f0d8", "k": "202020", "p": "e8c0a0"}, "rows": [
		"ww..........ww",
		"www..pppp..www",
		"wwwwppppppwwww",
		".wwwpkppkpwww.",
		"..wwppppppww..",
		"...oyyyyyyo...",
		"...oyYyyYyo...",
		"..oyyyyyyyyo..",
		"..oYYYYYYYYo..",
		"...ooooooooo..",
		".......kk.....",
	]},
	"cloud_puff": {"pal": {"o": "40485a", "w": "f4f6fc", "g": "c4cad8", "k": "303848"}, "rows": [
		"....oooo.......",
		"..ooggwwoooo...",
		".owwwwwwwwwwoo.",
		"owwwwwwwwwwwwwo",
		"owwkkwwwwkkwwwo",
		"owwkkwwwwkkwwwo",
		"owwwwwwwwwwwwgo",
		".owwwwwwwwwggo.",
		"..oogggggggoo..",
		"....oooooooo...",
	]},
	"gilded_moth": {"pal": {"o": "5a4410", "y": "f4d77a", "Y": "c8a038", "w": "fff6c9", "k": "302810"}, "rows": [
		".yy......yy.",
		"yYYy.oo.yYYy",
		"yYwYyoyyYwYy",
		".yYYyooyYYy.",
		"..yy.kk.yy..",
		".....kk.....",
	]},
	"dove_scout": {"pal": {"o": "3a3a4a", "w": "f4f4fa", "g": "bcbccc", "y": "ffa830", "k": "181820"}, "rows": [
		"...........oo.",
		"..gg......owwo",
		".gwwg..ooowwko",
		"gwwwwgowwwwwyy",
		".gwwwwwwwwwwo.",
		"..gwwwwwwwwo..",
		"...ogwwwwoo...",
		"....oo..oo....",
	]},
	"star_shard": {"pal": {"o": "5a4a10", "y": "ffe860", "Y": "e0b828", "w": "fffff0", "k": "403000"}, "rows": [
		".....oo.....",
		".....oyo....",
		"....oyyyo...",
		"ooooyywyyoooo",
		".oyyywwwyyyo.",
		"..oyyykyyyo..",
		"...oyyyyyo...",
		"..oyyYoYyyo..",
		".oyyo...oyyo.",
		"oyo.......oyo",
	]},
}

static var _cache := {}

static func _col(h: String) -> Color:
	return Color(h)

## Draws sprite centred on `at`. `cell` = world px per sprite pixel.
static func draw(ci: CanvasItem, spr: Dictionary, at: Vector2, cell: float, flash: float = 0.0, tint: Color = Color.WHITE) -> void:
	var rows: Array = spr["rows"]
	var pal: Dictionary = spr["pal"]
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var h := rows.size()
	var org := at - Vector2(w * cell * 0.5, h * cell * 0.5)
	for y in h:
		var row: String = rows[y]
		var x := 0
		while x < row.length():
			var ch := row[x]
			if ch == "." or not pal.has(ch):
				x += 1
				continue
			var x2 := x
			while x2 + 1 < row.length() and row[x2 + 1] == ch:
				x2 += 1
			var c: Color = _col(pal[ch]) * tint
			if flash > 0.0:
				c = c.lerp(Color.WHITE, flash * 0.7)
			ci.draw_rect(Rect2(org.x + x * cell, org.y + y * cell, (x2 - x + 1) * cell, cell), c)
			x = x2 + 1
