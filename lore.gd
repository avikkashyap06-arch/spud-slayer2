class_name Lore
extends RefCounted
## Lore bible + 50-boss table for "SPUD: WRATH OF THE SOIL".
## Quotes marked [BIBLE] are verbatim from the lore bible. Every other line is
## original filler written in the same voice and can be replaced freely.

const GAME_TITLE := "SPUD: WRATH OF THE SOIL"

const PREMISE := [
	"Before Heaven built its golden cathedrals and Hell lit its eternal furnaces, there was only the Soil — ancient, quiet, and enduring.",
	"From the deepest roots of the mortal earth rose Spud, a raw, heavy potato forged into sentient life by primal earth magic.",
	"For millennia, God and Satan waged a cosmic proxy war, trampling the soil beneath their armies. When their celestial treaty demanded the harvest and consumption of all mortal life, Spud refused to rot in the dirt.",
	"Wielding a razor-sharp Root-Blade grown from his own skin, Spud marched straight to the Gates of High Heaven to kill the Creator Himself.",
]

# [BIBLE] prologue / finale lines
const GOD_PROLOGUE_INTRO := "A lump of dirt dares crawl upon My marble? Return to the rot from whence you sprouted."
const TITLE_CARD := "CAST INTO THE ASH. CLIMB BACK TO THE LIGHT."
const SATAN_INTRO := "So the Creator threw away His leftovers. Come, little root—let us see if you burn or if you break."
const GOD_REMATCH_INTRO := "You clawed your way out of the pit, stained in ash and sin. Very well, child of the soil—let us finish this."

const ACT1_NAME := "ACT I: THE 9 LAYERS OF HELL"
const ACT2_NAME := "ACT II: THE GATES OF HEAVEN"
const ACT2_NARRATIVE := "The armies of Heaven panic as the \"dirt-born abomination\" climbs out of Hell's abyss, burning with stolen demonic fire."

const PROLOGUE_NAME := "THE THRONE OF LIGHT"

const WINGS_TEXT := "Satan's Hellfire Wings tear free.\nPermanent DOUBLE JUMP & AIR DASH unlocked.\nThe portal to Heaven rips open above you."
const ENDING_LINES := [
	"Spud shatters the Throne of Light.",
	"The stolen essence flows back into the mortal soil.",
	"And a lump of dirt walks away — the new sovereign of the earth.",
]

# --- Runes (index 0..3) ------------------------------------------------------
# cost = rune energy, cd = cooldown seconds
const RUNES := [
	{"name": "Bramble Spike", "school": "Earth", "tag": "Default", "cost": 20.0, "cd": 2.0,
		"desc": "Summons jagged roots from the arena floor beneath the boss.", "col": Color("7fbf4a")},
	{"name": "Brimstone Wrath", "school": "Hell", "tag": "Unlocked in Act I", "cost": 30.0, "cd": 3.0,
		"desc": "Launches explosive hellfire orbs.", "col": Color("ff6a1f")},
	{"name": "Divine Smite", "school": "Heaven", "tag": "Stolen in Act II", "cost": 45.0, "cd": 5.0,
		"desc": "Calls down a fast pillar of golden lightning.", "col": Color("ffe27a")},
	{"name": "Petrified Skin", "school": "Defense", "tag": "Defense", "cost": 25.0, "cd": 12.0,
		"desc": "Hardens Spud's potato skin into stone to block 1 incoming hit.", "col": Color("9aa0a8")},
]
# boss index after which each rune unlocks (0 = from the start of Act I)
const RUNE_UNLOCK_AFTER := [0, 4, 26, 8]

const UPGRADES := [
	{"name": "Thicker Skin", "stat": "Max HP", "desc": "Regrow thicker skin. +1 Max HP."},
	{"name": "Deeper Roots", "stat": "Stamina", "desc": "Deepen your roots. +10 Max Stamina."},
	{"name": "Sharper Blade", "stat": "Attack", "desc": "Sharpen the Root-Blade. +Attack Damage."},
]
const MAX_UPGRADE_LEVEL := 12

## Target length of one boss fight for a competent player, in seconds (tune to taste).
const TARGET_FIGHT_SECONDS := 80.0

static func upgrade_cost(kind: int, lvl: int) -> int:
	match kind:
		0: return 15 + 10 * lvl
		1: return 12 + 8 * lvl
		_: return 18 + 10 * lvl

# --- Families ----------------------------------------------------------------
# fly: hovers.  pool: attack patterns.  p2: extra patterns in later phases.
const FAMILIES := {
	"imp": {"label": "Brimstone Imp", "size": Vector2(70, 70), "fly": true, "hell": true,
		"col": Color("d9381e"), "acc": Color("ffa31a"),
		"pool": ["fan", "dive", "ring"], "p2": ["rain"], "hpm": 0.8},
	"wraith": {"label": "Ash Wraith", "size": Vector2(80, 120), "fly": true, "hell": true,
		"col": Color("6b6470"), "acc": Color("b8a9ff"),
		"pool": ["homing", "fan", "pillars"], "p2": ["ring"], "hpm": 0.9},
	"hound": {"label": "Cinder Hound", "size": Vector2(130, 80), "fly": false, "hell": true,
		"col": Color("3a2420"), "acc": Color("ff7a1a"),
		"pool": ["charge", "leap", "wave"], "p2": ["fan"], "hpm": 1.0},
	"slime": {"label": "Magma Slime", "size": Vector2(120, 90), "fly": false, "hell": true,
		"col": Color("e8541c"), "acc": Color("ffd23f"),
		"pool": ["leap", "rain", "wave"], "p2": ["ring"], "hpm": 1.1},
	"duke": {"label": "Duke of Hell", "size": Vector2(90, 170), "fly": false, "hell": true,
		"col": Color("7a1424"), "acc": Color("ff5a3c"),
		"pool": ["fan", "wave", "pillars", "charge"], "p2": ["ring", "homing"], "hpm": 1.0},
	"torturer": {"label": "Iron Torturer", "size": Vector2(120, 170), "fly": false, "hell": true,
		"col": Color("4a4d55"), "acc": Color("ff8a2a"),
		"pool": ["charge", "wave", "leap", "pillars"], "p2": ["fan"], "hpm": 1.1},
	"golem": {"label": "Hellfire Golem", "size": Vector2(170, 200), "fly": false, "hell": true,
		"col": Color("2b2326"), "acc": Color("ff6a1f"),
		"pool": ["wave", "leap", "rain", "pillars"], "p2": ["ring", "charge"], "hpm": 1.3},
	"seraph": {"label": "Fallen Seraph", "size": Vector2(100, 150), "fly": true, "hell": true,
		"col": Color("3b2a3e"), "acc": Color("ff9d2e"),
		"pool": ["fan", "homing", "pillars", "ring"], "p2": ["dive", "rain"], "hpm": 1.1},
	"cherub": {"label": "Gilded Cherub", "size": Vector2(80, 80), "fly": true, "hell": false,
		"col": Color("f4d77a"), "acc": Color("fff6c9"),
		"pool": ["fan", "ring", "homing"], "p2": ["rain"], "hpm": 0.9},
	"knight": {"label": "Choir Knight", "size": Vector2(100, 170), "fly": false, "hell": false,
		"col": Color("a4afba"), "acc": Color("d9423c"),
		"pool": ["charge", "fan", "leap", "wave"], "p2": ["pillars"], "hpm": 1.0},
	"pillar": {"label": "Pillar Guardian", "size": Vector2(110, 230), "fly": false, "hell": false,
		"col": Color("d9d4c4"), "acc": Color("ffcf4a"),
		"pool": ["pillars", "rain", "wave", "ring"], "p2": ["homing"], "hpm": 1.3},
	"ophanim": {"label": "Ophanim (Wheel Angel)", "size": Vector2(140, 140), "fly": true, "hell": false,
		"col": Color("e2b84a"), "acc": Color("ffffff"),
		"pool": ["ring", "homing", "dive", "fan"], "p2": ["pillars"], "hpm": 1.1},
	"archangel": {"label": "Archangel", "size": Vector2(110, 180), "fly": true, "hell": false,
		"col": Color("f2f2ff"), "acc": Color("ffd75e"),
		"pool": ["fan", "pillars", "judgment", "dive", "homing", "spears"], "p2": ["ring", "rain"], "hpm": 1.2},
	"satan": {"label": "Lord of the Abyss", "size": Vector2(200, 300), "fly": false, "hell": true,
		"col": Color("8c0f17"), "acc": Color("ff5a1f"),
		"pool": ["fan", "rain", "wave", "charge", "pillars", "leap"], "p2": ["ring", "homing", "judgment"], "hpm": 1.7},
	"god": {"label": "The Creator", "size": Vector2(190, 330), "fly": false, "hell": false,
		"col": Color("ffe9a0"), "acc": Color("ffffff"),
		"pool": ["fan", "wave", "pillars", "spears", "homing", "rain"], "p2": ["ring", "judgment", "charge"], "hpm": 1.9},
}

# [name, family, optional archangel key]  index 0 unused
const TABLE := [
	[],
	# --- The Ash Pits (1-10)
	["Snik", "imp"], ["Whisper", "wraith"], ["Scorchfang", "hound"], ["Gloop", "slime"],
	["Pyx the Tongueburner", "imp"], ["Veil of Embers", "wraith"], ["Kerbur", "hound"],
	["Slag Mother", "slime"], ["Malrik the Warlock-Imp", "imp"], ["The Hollow Queen", "wraith"],
	# --- The Infernal Citadel (11-24)
	["Duke Malphas", "duke"], ["Grisk the Rack-Warden", "torturer"], ["Ember Colossus", "golem"],
	["Nyx, the Singed Seraph", "seraph"], ["Duke Vassago", "duke"], ["Hooksmith Orrn", "torturer"],
	["The Furnace Titan", "golem"], ["Kaelith, Ashen Wing", "seraph"], ["Duke Gremory", "duke"],
	["Vess, Mistress of Chains", "torturer"], ["Magmaheart Behemoth", "golem"],
	["Ildrath, the Wingless Choir", "seraph"], ["Duke Amdusias", "duke"],
	["Lucent, the Last Fallen", "seraph"],
	# --- Satan
	["Satan, Lord of the Abyss", "satan"],
	# --- The Outer Clouds (26-39)
	["Pip", "cherub"], ["Sir Aurelian", "knight"], ["Pillar of Mercy", "pillar"],
	["Ophan Galgal", "ophanim"], ["Halo", "cherub"], ["Sir Caelum, Voice of the Choir", "knight"],
	["Pillar of Patience", "pillar"], ["Ophan Rotae", "ophanim"], ["Aurum", "cherub"],
	["Dame Ysolde", "knight"], ["Pillar of Obedience", "pillar"], ["Ophan of Many Eyes", "ophanim"],
	["The Regent Cherub", "cherub"], ["Sir Valorian, Captain of the Choir", "knight"],
	# --- The High Sanctuary (40-49): the Seven Archangels, the last three returning Wrathful
	["Raguel, Warden of Justice", "archangel", "raguel"], ["Sariel, Keeper of Oaths", "archangel", "sariel"],
	["Uriel, Flame of God", "archangel", "uriel"], ["Raphael, Healer of the Host", "archangel", "raphael"],
	["Gabriel, Herald of the Horn", "archangel", "gabriel"], ["Michael, Prince of the Host", "archangel", "michael"],
	["Metatron, Voice of the Creator", "archangel", "metatron"],
	["Gabriel, Horn of Ruin (Wrathful)", "archangel", "gabriel"],
	["Michael, Sword of Heaven (Wrathful)", "archangel", "michael"],
	["Metatron, Scribe of the End (Wrathful)", "archangel", "metatron"],
	# --- True final boss
	["God, The Creator", "god"],
]

const ARCH_COLORS := {
	"raguel": Color("9ad6ff"), "sariel": Color("c9b3ff"), "uriel": Color("ffb347"),
	"raphael": Color("9affb4"), "gabriel": Color("fff2a8"), "michael": Color("ff7a6e"),
	"metatron": Color("ffffff"),
}
const ARCH_INTRO := {
	"raguel": "Justice does not bend for the humble, nor does it break for the proud. Stand, and be weighed.",
	"sariel": "I keep the oaths of Heaven. You swore to kill the Creator. I swear you will not.",
	"uriel": "I am the flame that watched your world burn, little root. I did not weep.",
	"raphael": "I have healed ten thousand angels. I will gladly make an exception.",
	"gabriel": "Hear the Horn! It sounded the first morning — and it will sound your last.",
	"michael": "Prince of the Host, sword of the Throne. Dirt does not get to climb the stairs.",
	"metatron": "I wrote your name in the Book of Rot before you were seeded. Allow me to close the page.",
}
const ARCH_OUTRO := {
	"raguel": "The scales... tip toward the soil?",
	"sariel": "An oath... broken. By a vegetable.",
	"uriel": "Flame... flickers. How strange — it feels like rain.",
	"raphael": "I cannot mend... this one. Go on, then.",
	"gabriel": "The Horn... falls silent.",
	"michael": "My sword... was never meant to be... outlasted.",
	"metatron": "The page... is torn. Write what you will.",
}
const ARCH_WRATH_INTRO := {
	"gabriel": "The Horn sounds again — and this time, it sounds for ruin!",
	"michael": "You wounded me once. The Host does not forgive twice.",
	"metatron": "The Book has been rewritten in your blood. Let me read you the last line.",
}

# Original filler quotes per family (intro, outro)
const FAM_INTRO := {
	"imp": ["Fresh root! The Dukes pay double for roasted ones!", "Tiny dirt, tiny fire — watch me make you smaller!", "Is that a potato? Mother always said they burn well!"],
	"wraith": ["We were mortals once. We tasted of soil. Come, join us.", "Cold earth, warm ash — you belong to neither.", "Sprout, sprout, little seed... wither, wither."],
	"hound": ["*The Cinder Hound's eyes ignite. It smells living earth for the first time in an age.*", "*A growl rolls out of the dark like a landslide.*", "*Embers drip from its jaws. It is very, very hungry.*"],
	"slime": ["*The Magma Slime bubbles hungrily and rolls toward you.*", "*Something molten and furious oozes out of the wall.*", "*It sizzles. It swells. It wants to be bigger than you.*"],
	"duke": ["Kneel, root. In this citadel, even the dirt has a master.", "A vegetable, here? Bring the salt. Bring the fire.", "I have judged kings. I will not be troubled by a tuber."],
	"torturer": ["Fresh meat for the rack! ...no — fresh *vegetable*. Even better.", "My hooks have waited an age for a skin this thick.", "Hold still. Mashing is so much easier when you hold still."],
	"golem": ["*FURNACE HEART IGNITES. TARGET: ROOT. PURPOSE: ASH.*", "*IRON JOINTS GROAN. THE CITADEL WALLS SHAKE.*", "*TARGET LOCKED. TARGET IS: DIRT.*"],
	"seraph": ["I once sang before the Throne. Now I burn beside it. You will not climb past me.", "Do you hear it? The old hymn, burning down to cinders. Join the chorus.", "Beautiful, isn't it — to fall? Let me show you."],
	"cherub": ["Intruder! Intruder! Ring the bells! There's dirt on the clouds!", "Shoo, shoo! The Creator doesn't want mud on His pearly floors!", "Eek! A root! A rude root!"],
	"knight": ["By the Creator's will, thou shalt not pass these clouds!", "Halt, abomination of the earth! The Choir shall sing thy end.", "Thy fire is stolen, thy roots are foul. Turn back."],
	"pillar": ["*The Pillar's stone eyes open, ancient as the first sunrise.*", "I have held up Heaven for ten thousand years. I will not fall to a root.", "*The clouds tremble. Something very old is awake.*"],
	"ophanim": ["*Wheels within wheels turn, a thousand eyes all fixed upon the dirt.*", "*A ring of light, a hum like the sea. It sees every part of you.*", "*Eyes open on every rim. None of them blink.*"],
}
const FAM_OUTRO := {
	"imp": ["Ow... it burns... backwards...", "The ash... remembers you, root...", "Mother... was right... about the burning..."],
	"wraith": ["The soil... it calls us... home...", "So warm... so... green...", "I remember... rain..."],
	"hound": ["*The hound whimpers and curls into cooling embers.*", "*It lowers its head. Something like gratitude flickers in its eyes.*", "*Its fire gutters out, and the cavern grows quiet.*"],
	"slime": ["*It hisses into a puddle of black glass.*", "*The slime cools, cracks, and sets into obsidian.*", "*One last bubble pops. Silence.*"],
	"duke": ["Impossible... a vegetable... bested a Duke of Hell...", "My name... was written in fire. Yours is written in dirt. Why does yours last?", "Tell the Abyss... the roots... are coming."],
	"torturer": ["The chains... they're rusting... so quickly...", "No one... has ever... mashed me...", "Hooks... fall... silent..."],
	"golem": ["*HEART... COOLING... SOIL... WARM...*", "*SYSTEMS... FAILING. THANK... YOU.*", "*FIRE... OUT. EARTH... REMAINS.*"],
	"seraph": ["Tell Him... that I remember the song...", "The fire... is so quiet... when it stops...", "Go up, little root. Go up. And sing."],
	"cherub": ["Oh... my halo... it's all smudged...", "It was only... a little dirt...", "Tell the others... to hide..."],
	"knight": ["I yield... what manner of soil is this...", "My oath... was to Heaven. Not to the Creator. Go.", "The Choir... falls silent..."],
	"pillar": ["*Cracks race up its length... and the pillar finally rests.*", "I held... so long. Let someone else hold.", "*The stone sighs, crumbles, and is only dust again.*"],
	"ophanim": ["*The wheels slow... the eyes close, one by one.*", "*Its ring of light flickers out like a candle.*", "*The hum fades. The sky is suddenly very quiet.*"],
}
const SATAN_OUTRO := "The Creator... will devour you too, little root. We were never enemies. We were... dinner guests."
const GOD_OUTRO := "Child of the soil... so this is what it is... to be forgotten. Let it be... gentle."

static func layer_for(i: int) -> int:
	# Spud is cast into the 9th Pit and climbs UP: boss 1 -> Layer 9, boss 25 -> Layer 1
	return clampi(9 - int(floor(float(i - 1) * 9.0 / 25.0)), 1, 9)

static func area_name(i: int) -> String:
	if i <= 10: return "The Ash Pits — Layer %d" % layer_for(i)
	if i <= 24: return "The Infernal Citadel — Layer %d" % layer_for(i)
	if i == 25: return "The Abyssal Throne"
	if i <= 39: return "The Outer Clouds"
	if i <= 49: return "The High Sanctuary"
	return "The Throne of Light"

static func act_for(i: int) -> int:
	return 1 if i <= 25 else 2

static func ash_reward(i: int) -> int:
	return 22 + 3 * i

## Returns a Dictionary describing boss number i (1..50).
static func boss(i: int) -> Dictionary:
	var row: Array = TABLE[i]
	var fam_key: String = row[1]
	var fam: Dictionary = FAMILIES[fam_key]
	var d := {}
	d["index"] = i
	d["name"] = row[0]
	d["family"] = fam_key
	d["label"] = fam["label"]
	d["size"] = fam["size"]
	d["fly"] = fam["fly"]
	d["hell"] = fam["hell"]
	d["col"] = fam["col"]
	d["acc"] = fam["acc"]
	d["pool"] = (fam["pool"] as Array).duplicate()
	d["p2"] = (fam["p2"] as Array).duplicate()
	d["arch"] = ""
	var t := float(i) / 50.0
	d["tier"] = t
	# HP is sized so an average player (damage ~ 10 + 0.6*i, ~1.3x effective hits/sec)
	# needs about TARGET_FIGHT_SECONDS to win. Final bosses are longer (three phases).
	var hpm := clampf(float(fam["hpm"]), 0.9, 1.15)
	if i == 25 or i == 50:
		hpm = 1.5
	d["hp"] = TARGET_FIGHT_SECONDS * 1.3 * (10.0 + 0.6 * float(i)) * hpm
	var ease_f := lerpf(0.7, 1.0, clampf(float(i - 1) / 24.0, 0.0, 1.0))
	d["ease"] = ease_f
	d["speed"] = (90.0 + 90.0 * t) * (0.8 + 0.2 * ease_f) * 0.92
	d["cd"] = (1.7 - 0.8 * t) / ease_f * 1.15
	d["bolt_speed"] = (250.0 + 230.0 * t) * ease_f * 0.9
	d["dmg"] = 2 if i >= 44 else 1
	d["phases"] = 2
	d["final"] = false
	d["style"] = "fire" if fam["hell"] else "holy"
	# quotes
	var intro := ""
	var outro := ""
	if i == 25:
		intro = SATAN_INTRO; outro = SATAN_OUTRO; d["phases"] = 3; d["final"] = true; d["dmg"] = 2
	elif i == 50:
		intro = GOD_REMATCH_INTRO; outro = GOD_OUTRO; d["phases"] = 3; d["final"] = true; d["dmg"] = 2
	elif fam_key == "archangel":
		var k: String = row[2]
		d["arch"] = k
		d["col"] = ARCH_COLORS[k]
		if i >= 47:
			intro = ARCH_WRATH_INTRO[k]
			d["hp"] = float(d["hp"]) * 1.15
		else:
			intro = ARCH_INTRO[k]
		outro = ARCH_OUTRO[k]
		d["style"] = "holy"
	else:
		var ins: Array = FAM_INTRO[fam_key]
		var outs: Array = FAM_OUTRO[fam_key]
		intro = ins[i % ins.size()]
		outro = outs[(i + 1) % outs.size()]
	d["intro"] = intro
	d["outro"] = outro
	d["title"] = fam["label"] if not d["final"] and fam_key != "archangel" else (fam["label"] if fam_key == "archangel" else fam["label"])
	return d

## The playable prologue God (ankle-hits only; never takes real damage)
static func god_prologue() -> Dictionary:
	var d := boss(50)
	d["name"] = "God, The Creator"
	d["intro"] = GOD_PROLOGUE_INTRO
	d["prologue"] = true
	return d
