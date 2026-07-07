extends Node2D

## Young tree planted by a Forester Lodge. Grows into a mature tree in Task 9.

func _ready() -> void:
	SaplingRegistry.register_sapling(self)

func _exit_tree() -> void:
	SaplingRegistry.unregister_sapling(self)
