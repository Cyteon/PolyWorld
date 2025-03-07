extends BaseItem
class_name ToolItem

# when reach 100, poof
@export var durability: int = 100

# Will take 5 damage, and reduce dur by 3, when used to attack entity
@export var damage: int = 5
@export var attacking_reduces_dur_by: int = 3

enum ToolType {
	MINING,
	HARVESTING,
	WEAPON
}

@export var type: ToolType

# Example: tree is 100, 10 hits required to down tree
@export var harvestable_damage: int = 10
@export var harvesting_reduces_dur_by: int = 2

# We use harvestable/harvesting even if its mining for simplicity

var is_ready = true

func _process(_delta: float) -> void:
	if get_parent().name != "Hold": return
	
	if Input.is_action_just_pressed("use"):
		if len(get_parent().get_parent().hotbar_items) >= get_parent().get_parent().current_hotbar_slot:
			var slot = get_parent().get_parent().hotbar_items[get_parent().get_parent().current_hotbar_slot - 1]
			
			if slot.unique_id == unique_id and is_ready:
				$AnimationPlayer.play("use")
				Network.rpc("_play_item_anim", get_parent().get_parent().name.to_int())
				is_ready = false
				
				if get_parent().get_parent().get_node("Camera3D/ShortRaycast").is_colliding() and (
					get_parent().get_parent().get_node("Camera3D/ShortRaycast")
						.get_collider().is_in_group("Harvestable") and type == ToolType.HARVESTING
					or get_parent().get_parent().get_node("Camera3D/ShortRaycast")
						.get_collider().is_in_group("Mineable") and type == ToolType.MINING
				): # We use this to see if its being used :P
					var collider = get_parent().get_parent().get_node("Camera3D/ShortRaycast").get_collider()
					
					durability -= harvesting_reduces_dur_by
					
					get_parent().get_parent().hotbar_items[
						get_parent().get_parent().current_hotbar_slot - 1
					].durability -= harvesting_reduces_dur_by
					
					if get_parent().get_parent().hotbar_items[
						get_parent().get_parent().current_hotbar_slot - 1
					].durability <= 0:
						get_parent().get_parent().hotbar_items.remove_at(get_parent().get_parent().current_hotbar_slot - 1)
					
					collider.damage(harvestable_damage)
					
					# TODO: Maybe optimize som code in player.gd to be nice like this and not just copy every to a BaseItem.new() :sob:
					
					var item = collider.yields.duplicate() as BaseItem
					for child in item.get_children():
						child.free()
					
					item.item_count = collider.yields_per_damage * harvestable_damage
					
					get_parent().get_parent().add_item_to_inv(item)
				elif damage > 0 and get_parent().get_parent().get_node("Camera3D/ShortRaycast").is_colliding():
					var collider = get_parent().get_parent().get_node("Camera3D/ShortRaycast").get_collider()
					
					if collider.is_in_group("Player"):
						Network.rpc_id(1, "_attack_player", collider.name.to_int(), damage)


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	is_ready = true
