@tool
extends StaticBody2D

const SEGMENT_WIDTH = 64
const SPRITE_SCALE = Vector2(4, 4)

@export_range(2, 10) var tiles: int = 2 : set = _set_tiles
@export var inner_tile_texture: Texture2D


func _set_tiles(new_tiles: int) -> void:
	tiles = new_tiles
	_regenerate_collision()
	_place_start_and_end_sprites()
	_place_inner_tiles()


func _regenerate_collision() -> void:
	$Collision.shape.size.x = tiles * SEGMENT_WIDTH


func _place_start_and_end_sprites() -> void:
	var distance = (tiles - 1) * SEGMENT_WIDTH / 2
	$StartSprite.position.x = -distance
	$EndSprite.position.x = distance


func _place_inner_tiles() -> void:
	for child in $InnerSprites.get_children():
		child.queue_free()
	
	if tiles == 2:
		return
	
	var positions: Array[int] = []
	if tiles == 3:
		positions.append(0)
	else:
		var inner_tiles = tiles - 2
		var bound = (inner_tiles - 1) * SEGMENT_WIDTH / 2
		for tile_position in range(-bound, bound + 1, SEGMENT_WIDTH):
			positions.append(tile_position)
	
	for tile_position in positions:
		var sprite = Sprite2D.new()
		sprite.scale = SPRITE_SCALE
		sprite.texture = inner_tile_texture
		sprite.position.x = tile_position
		$InnerSprites.add_child(sprite)
