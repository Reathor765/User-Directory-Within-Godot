@tool
extends EditorPlugin

var dock: VBoxContainer
var tree: Tree
var refresh_button: Button
var popup_menu: PopupMenu
var selected_item: TreeItem
var selected_path: String

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.set_name("UserDir")

	refresh_button = Button.new()
	refresh_button.set_text("Refresh")
	refresh_button.connect("pressed", _refresh_tree)
	dock.add_child(refresh_button)

	tree = Tree.new()
	tree.set_columns(1)
	tree.set_hide_root(true)
	tree.connect("item_activated", _on_item_activated)
	tree.connect("item_mouse_selected", _on_item_mouse_selected)
	# Enable drag and drop
	tree.set_allow_rmb_select(true)
	tree.connect("button_clicked", _on_button_clicked)
	tree.set_drag_forwarding(func(): return self, func(at): return _can_drop_data(at), func(at, data): return _drop_data(at, data))
	dock.add_child(tree)
	tree.set_v_size_flags(Control.SIZE_EXPAND_FILL)

	# Create context menu
	popup_menu = PopupMenu.new()
	popup_menu.connect("id_pressed", _on_popup_menu_item_selected)
	popup_menu.add_item("Open in Inspector", 0)
	popup_menu.add_separator()
	popup_menu.add_item("Copy Path", 1)
	popup_menu.add_separator()
	popup_menu.add_item("Rename...", 2)
	popup_menu.add_item("Delete", 3)
	tree.add_child(popup_menu)

	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)
	_refresh_tree()

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.free()

func _refresh_tree() -> void:
	# Save the collapsed state of all folders before clearing
	var collapsed_state := _save_tree_state()
	
	tree.clear()
	var root = tree.create_item()
	_scan_dir(root, "user://")
	
	# Restore the collapsed state after rebuilding
	_restore_tree_state(collapsed_state)

## Recursively saves the collapsed state of all tree items
func _save_tree_state() -> Dictionary:
	var state := {}
	var root := tree.get_root()
	if root:
		_save_item_state(root, state)
	return state

## Helper to recursively save state for a tree item and its children
func _save_item_state(item: TreeItem, state: Dictionary) -> void:
	var path = item.get_metadata(0)
	if path:
		state[path] = item.collapsed
	
	var child := item.get_first_child()
	while child:
		_save_item_state(child, state)
		child = child.get_next()

## Recursively restores the collapsed state of all tree items
func _restore_tree_state(state: Dictionary) -> void:
	var root := tree.get_root()
	if root:
		_restore_item_state(root, state)

## Helper to recursively restore state for a tree item and its children
func _restore_item_state(item: TreeItem, state: Dictionary) -> void:
	var path = item.get_metadata(0)
	if path and path in state:
		item.collapsed = state[path]
	
	var child := item.get_first_child()
	while child:
		_restore_item_state(child, state)
		child = child.get_next()


func _scan_dir(parent_item: TreeItem, path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var item = tree.create_item(parent_item)
				item.set_text(0, file_name)
				var new_path = path.path_join(file_name)
				item.set_metadata(0, new_path)  # Store full path in metadata
				
				if dir.current_is_dir():
					item.set_icon(0, EditorInterface.get_base_control().get_theme_icon("Folder", "EditorIcons"))
					item.set_icon_modulate(0, Color(0.29, 0.471, 0.596))
					item.collapsed = true  # Make folders collapsed by default
					
					_scan_dir(item, new_path)
				else:
					# Set appropriate icon based on file type
					var icon_name = "File"
					var ext = file_name.get_extension().to_lower()
					match ext:
						"txt", "md", "json", "cfg", "ini":
							icon_name = "TextFile"
						"tres", "res":
							icon_name = "ResourcePreloader"
						"tscn":
							icon_name = "PackedScene"
						"gd":
							icon_name = "GDScript"
					item.set_icon(0, EditorInterface.get_base_control().get_theme_icon(icon_name, "EditorIcons"))
					
			file_name = dir.get_next()
		dir.list_dir_end()

func _on_item_activated() -> void:
	var selected = tree.get_selected()
	if selected:
		var path = selected.get_metadata(0)
		if path and not DirAccess.dir_exists_absolute(path):
			# Open the file in the editor
			var ext = path.get_extension().to_lower()
			match ext:
				"txt", "md", "json", "cfg", "ini", "gd":
					EditorInterface.edit_resource(load(path))
				"tres", "res":
					# Force reload from disk by clearing cache first
					if ResourceLoader.has_cached(path):
						var old_resource = ResourceLoader.load(path)
						if old_resource:
							old_resource.take_over_path("")  # Remove from cache
					# Now load fresh from disk
					var resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
					if resource:
						# Re-assign the path so the resource knows where to save
						resource.resource_path = path
						# Mark it as changed so Godot will prompt to save
					EditorInterface.edit_resource(resource)
				"tscn":
					EditorInterface.open_scene_from_path(path)

func _on_item_mouse_selected(_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		selected_item = tree.get_selected()
		if selected_item:
			selected_path = selected_item.get_metadata(0)
			popup_menu.popup(Rect2i(get_viewport().get_mouse_position(), Vector2i(1, 1)))

func _on_popup_menu_item_selected(id: int) -> void:
	if not selected_item or not selected_path:
		return
		
	match id:
		0:  # Open
			_on_item_activated()
		1:  # Copy Path
			DisplayServer.clipboard_set(selected_path)
		2:  # Rename
			_rename_item()
		3:  # Delete
			_delete_item()

func _rename_item() -> void:
	if not selected_item or not selected_path:
		return
	
	# Get current name
	var old_name = selected_item.get_text(0)
	var dir_path = selected_path.get_base_dir()
	
	# Create rename dialog
	var dialog = ConfirmationDialog.new()
	var line_edit = LineEdit.new()
	line_edit.text = old_name
	dialog.add_child(line_edit)
	dialog.title = "Rename File"
	
	# Connect dialog signals
	dialog.connect("confirmed", func():
		var new_name = line_edit.text
		if new_name != old_name:
			var _new_path = dir_path.path_join(new_name)
			var dir = DirAccess.open(dir_path)
			if dir:
				# Attempt rename
				var err = dir.rename(old_name, new_name)
				if err == OK:
					_refresh_tree()
					print_debug("Renamed %s to %s" % [old_name, new_name])
				else:
					printerr("Failed to rename file: ", error_string(err))
	)
	
	# Show dialog
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()

func _delete_item() -> void:
	if not selected_item or not selected_path:
		return
	
	# Create confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Delete " + selected_item.get_text(0) + "?"
	dialog.title = "Confirm Delete"
	
	# Connect dialog signals
	dialog.connect("confirmed", func():
		var dir = DirAccess.open(selected_path.get_base_dir())
		if dir:
			# Check if it's a directory or file
			if DirAccess.dir_exists_absolute(selected_path):
				OS.move_to_trash(selected_path)  # Safer than recursive delete
			else:
				var err = dir.remove(selected_path.get_file())
				if err != OK:
					printerr("Failed to delete file: ", error_string(err))
			_refresh_tree()
	)
	
	# Show dialog
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()

func _on_button_clicked(item: TreeItem, _column: int, _id: int, mouse_button_index: int) -> Dictionary:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		# Start drag operation
		var drag_data = {
			"type": "files",
			"files": [item.get_metadata(0)]
		}
		tree.set_drop_mode_flags(Tree.DROP_MODE_ON_ITEM | Tree.DROP_MODE_INBETWEEN)
		tree.set_drag_preview(generate_drag_preview(item))
		return drag_data
	return {}

func generate_drag_preview(item: TreeItem) -> Control:
	var preview = HBoxContainer.new()
	var icon = TextureRect.new()
	icon.texture = item.get_icon(0)
	var label = Label.new()
	label.text = item.get_text(0)
	preview.add_child(icon)
	preview.add_child(label)
	return preview

func _can_drop_data(at_position: Vector2) -> bool:
	var item = tree.get_item_at_position(at_position)
	if not item:
		return false
	var drop_path = item.get_metadata(0)
	return DirAccess.dir_exists_absolute(drop_path)

func _drop_data(at_position: Vector2, data) -> bool:
	if not data is Dictionary or not "files" in data:
		return false
		
	var target_item = tree.get_item_at_position(at_position)
	if not target_item:
		return false
		
	var target_path = target_item.get_metadata(0)
	if not DirAccess.dir_exists_absolute(target_path):
		target_path = target_path.get_base_dir()
		
	# Move each dragged file to the target directory
	for file_path in data.files:
		var file_name = file_path.get_file()
		var new_path = target_path.path_join(file_name)
		
		# Don't move if source and destination are the same
		if file_path == new_path:
			continue
			
		var dir = DirAccess.open(file_path.get_base_dir())
		if dir:
			var err = dir.rename(file_path, new_path)
			if err != OK:
				printerr("Failed to move file: ", error_string(err))
				
	_refresh_tree()
	return true
