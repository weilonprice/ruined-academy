extends RefCounted

# Builds "<action>_<direction>" animations from <root>/<action>/<direction>/*.png.
# Any action without frames falls back to the still in <root>/rotations/<direction>.png.


static func build(root: String, directions: Array, speeds: Dictionary, one_shots: Array) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction: String in directions:
		var rotation_path := "%s/rotations/%s.png" % [root, direction]
		if not ResourceLoader.exists(rotation_path):
			continue
		var rotation := load(rotation_path) as Texture2D
		for action: String in speeds:
			var animation := "%s_%s" % [action, direction]
			frames.add_animation(animation)
			frames.set_animation_speed(animation, speeds[action])
			frames.set_animation_loop(animation, action not in one_shots)
			for texture in folder_frames("%s/%s/%s" % [root, action, direction]):
				frames.add_frame(animation, texture)
			if frames.get_frame_count(animation) == 0:
				frames.add_frame(animation, rotation)
	return frames


# The PNGs in a folder, in name order; empty if the folder is missing.
static func folder_frames(folder: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	if not DirAccess.dir_exists_absolute(folder):
		return textures
	# ResourceLoader also lists imported PNGs in exported builds, where the raw files are absent.
	var files := Array(ResourceLoader.list_directory(folder))
	files.sort()
	for file: String in files:
		if file.ends_with(".png"):
			textures.append(load(folder.path_join(file)))
	return textures


# The facing nearest to an offset; directions run clockwise from east, evenly spaced.
static func facing_toward(offset: Vector2, directions: Array) -> String:
	var step := TAU / directions.size()
	return directions[posmod(roundi(offset.angle() / step), directions.size())]
