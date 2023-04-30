extends Node2D

var individualSprite = preload("res://Terrain/DynamicPoleSprite.tscn")

const PIECE_HEIGHT = 16
const PIECE_WIDTH = 16
enum P { BOTTOM, MIDDLE, TOP }
var height = 0

func add_sprite(which_piece, height_):
	var sprite = individualSprite.instance()
	match which_piece:
		P.BOTTOM: sprite.frame = 1
		P.MIDDLE: sprite.frame = 0
		P.TOP: sprite.frame = 2
	sprite.position.y -= height_ * PIECE_HEIGHT
	sprite.centered = false
	add_child(sprite)		

func init(height_):
	# Should we reject 0-height towers?
	var idx = 0
	height = height_
	while idx <= height:
		# This is first so that we do the right thing for 1-height towers
		if idx == height:
			add_sprite(P.TOP, idx)
		elif idx == 0:
			add_sprite(P.BOTTOM, idx)
		else:
			add_sprite(P.MIDDLE, idx)
		idx += 1

func get_latchpoint():
	return global_position + Vector2(PIECE_WIDTH / 2, -PIECE_HEIGHT * height)