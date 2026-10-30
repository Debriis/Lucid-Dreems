extends RefCounted
## Only the world passes through this viewport and its retro post-processing.
static func attach(parent: Node, world: Node) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = "WorldViewport"
	viewport.size = Vector2i(320, 180)
	viewport.own_world_3d = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(viewport)
	if world.get_parent():
		world.reparent(viewport)
	else:
		viewport.add_child(world)
	var screen := TextureRect.new()
	screen.name = "WorldDisplay"
	screen.size = Vector2(1280, 720)
	screen.texture = viewport.get_texture()
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(screen)
	var effects := CanvasLayer.new()
	effects.name = "WorldEffects"
	viewport.add_child(effects)
	var overlay := ColorRect.new()
	overlay.size = Vector2(320, 180)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/dream.gdshader")
	overlay.material = material
	effects.add_child(overlay)
	return viewport
