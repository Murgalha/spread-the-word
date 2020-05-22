extends Control

func _on_Create_pressed():
	print("Creating")

func _on_Exit_pressed():
	get_tree().quit()

func _on_Join_pressed():
	get_tree().change_scene('res://scenes/Client.tscn')
