extends AudioStreamPlayer

enum TRACKS {
  ENDING,
  LOOP_GUITAR, 
  LOOP_MYSTERY,
  LOOP_STANDARD,
  LOOP_TECHNO_1,
  LOOP_TECHNO_2,
  }

const MUSIC: Dictionary = {
	TRACKS.ENDING: preload("res://assets/audio/music/ending.ogg"),
	TRACKS.LOOP_GUITAR: preload("res://assets/audio/music/loop_guitar.ogg"),
	TRACKS.LOOP_MYSTERY: preload("res://assets/audio/music/loop_mystery.ogg"),
	TRACKS.LOOP_STANDARD: preload("res://assets/audio/music/loop_standard.ogg"),
	TRACKS.LOOP_TECHNO_1: preload("res://assets/audio/music/loop_techno_1.ogg"),
	TRACKS.LOOP_TECHNO_2: preload("res://assets/audio/music/loop_techno_2.ogg"),
}

@export var current_music = TRACKS.LOOP_STANDARD

func _ready() -> void:
  # Play music
	self.stream = MUSIC[current_music]
	self.volume_db = -25
	self.stream.loop = true
	self.play()

func _process(delta: float) -> void:
	pass
