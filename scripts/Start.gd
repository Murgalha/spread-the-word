extends Node

func _ready():
	var args = Array(OS.get_cmdline_args())
	if args.has("-s"):
		print("starting server...")
		get_tree().change_scene("res://scenes/Server.tscn")
	else:
		print("Opening main menu")
		get_tree().change_scene("res://scenes/MainMenu.tscn")
