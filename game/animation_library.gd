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
			var folder := "%s/%s/%s" % [root, action, direction]
			if DirAccess.dir_exists_absolute(folder):
				# ResourceLoader also lists imported PNGs in exported builds, where the raw files are absent.
				var files := Array(ResourceLoader.list_directory(folder))
				files.sort()
				for file: String in files:
					if file.ends_with(".png"):
						frames.add_frame(animation, load(folder.path_join(file)))
			if frames.get_frame_count(animation) == 0:
				frames.add_frame(animation, rotation)
	return frames
