extends Control
## HUD controller. Displays resources and player actions.

@onready var resource_label: Label = $TopBar/ResourceLabel


func update_resources(amount: int) -> void:
	resource_label.text = "Resources: %d" % amount
