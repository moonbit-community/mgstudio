// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
pub let ecs_key_sprite : @ecs.ComponentKey[Sprite] = @ecs.register_component(
  debug_name="render2d.sprite",
)

///|
pub let ecs_key_anchor : @ecs.ComponentKey[Anchor] = @ecs.register_component(
  debug_name="render2d.anchor",
)

///|
pub let ecs_key_render_layers : @ecs.ComponentKey[RenderLayers] = @ecs.register_component(
  debug_name="render2d.render_layers",
)

///|
pub let ecs_key_camera2d : @ecs.ComponentKey[Camera2d] = @ecs.register_component(
  debug_name="render2d.camera2d",
)

///|
pub let ecs_key_camera : @ecs.ComponentKey[Camera] = @ecs.register_component(
  debug_name="render2d.camera",
)

///|
pub let ecs_key_projection : @ecs.ComponentKey[Projection] = @ecs.register_component(
  debug_name="render2d.projection",
)

///|
pub let ecs_key_render_target : @ecs.ComponentKey[RenderTarget] = @ecs.register_component(
  debug_name="render2d.render_target",
)

///|
pub let ecs_key_bloom2d : @ecs.ComponentKey[Bloom2d] = @ecs.register_component(
  debug_name="render2d.bloom2d",
)

///|
pub let ecs_key_mesh2d : @ecs.ComponentKey[Mesh2d] = @ecs.register_component(
  debug_name="render2d.mesh2d",
)

///|
pub let ecs_key_color_material : @ecs.ComponentKey[ColorMaterial] = @ecs.register_component(
  debug_name="render2d.color_material",
)

///|
pub let ecs_key_mesh_material2d : @ecs.ComponentKey[MeshMaterial2d] = @ecs.register_component(
  debug_name="render2d.mesh_material2d",
)

///|
pub let ecs_key_gpu_mesh2d : @ecs.ComponentKey[GpuMesh2d] = @ecs.register_component(
  debug_name="render2d.gpu_mesh2d",
)

///|
pub let ecs_key_scissor_rect : @ecs.ComponentKey[ScissorRect] = @ecs.register_component(
  debug_name="render2d.scissor_rect",
)

///|
pub let ecs_key_wireframe2d : @ecs.ComponentKey[Wireframe2d] = @ecs.register_component(
  debug_name="render2d.wireframe2d",
)

///|
pub let ecs_key_no_wireframe2d : @ecs.ComponentKey[NoWireframe2d] = @ecs.register_component(
  debug_name="render2d.no_wireframe2d",
)

///|
pub let ecs_key_wireframe2d_color : @ecs.ComponentKey[Wireframe2dColor] = @ecs.register_component(
  debug_name="render2d.wireframe2d_color",
)

///|
pub let ecs_key_clear_color_config : @ecs.ComponentKey[ClearColorConfig] = @ecs.register_component(
  debug_name="render2d.clear_color_config",
)

///|
pub let ecs_key_render_state : @ecs.ResourceKey[RenderState] = @ecs.register_resource(
  debug_name="render2d.render_state",
)

///|
pub let ecs_key_wireframe2d_config : @ecs.ResourceKey[Wireframe2dConfig] = @ecs.register_resource(
  debug_name="render2d.wireframe2d_config",
)

///|
fn[T] ecs_set_component_json(
  world : @ecs.World,
  entity : @core.Entity,
  key : @ecs.ComponentKey[T],
  payload : Json,
) -> Unit {
  let json_key : @ecs.ComponentKey[Json] = key.cast()
  try! (world.set(entity, json_key, payload) |> ignore)
}

///|
fn encode_color(color : Color) -> Json {
  (color.r, color.g, color.b, color.a).to_json()
}

///|
fn encode_vec2(value : @math.Vec2) -> Json {
  (value.x, value.y).to_json()
}

///|
fn encode_ivec2(value : @math.IVec2) -> Json {
  (value.x, value.y).to_json()
}

///|
fn encode_rect(rect : @math.Rect) -> Json {
  (rect.min.x, rect.min.y, rect.max.x, rect.max.y).to_json()
}

///|
fn encode_image_handle(handle : @asset.Handle[@asset.Image]) -> Json {
  handle.id().to_json()
}

///|
fn encode_mesh_handle(handle : @asset.Handle[@mesh.Mesh]) -> Json {
  handle.id().to_json()
}

///|
fn encode_color_material_asset_handle(
  handle : @asset.Handle[ColorMaterialAsset],
) -> Json {
  handle.id().to_json()
}

///|
fn encode_texture_atlas(texture_atlas : @asset.TextureAtlas) -> Json {
  (texture_atlas.layout.id(), texture_atlas.index).to_json()
}

///|
fn encode_slice_scale_mode(mode : SliceScaleMode) -> Json {
  match mode {
    Stretch => (0, Json::null()).to_json()
    Tile(value) => (1, value.to_json()).to_json()
  }
}

///|
fn encode_sprite_scaling_mode(mode : SpriteScalingMode) -> Json {
  match mode {
    FillCenter => (0).to_json()
    FillStart => (1).to_json()
    FillEnd => (2).to_json()
    FitCenter => (3).to_json()
    FitStart => (4).to_json()
    FitEnd => (5).to_json()
  }
}

///|
fn encode_sprite_tiling(tiling : SpriteTiling) -> Json {
  (tiling.tile_x, tiling.tile_y, tiling.stretch_value).to_json()
}

///|
fn encode_border_rect(border : BorderRect) -> Json {
  (border.left, border.right, border.top, border.bottom).to_json()
}

///|
fn encode_texture_slicer(slicer : TextureSlicer) -> Json {
  (
    encode_border_rect(slicer.border),
    encode_slice_scale_mode(slicer.center_scale_mode),
    encode_slice_scale_mode(slicer.sides_scale_mode),
    slicer.max_corner_scale,
  ).to_json()
}

///|
fn encode_sprite_image_mode(mode : SpriteImageMode) -> Json {
  match mode {
    Auto => (0, Json::null()).to_json()
    Scale(scaling_mode) =>
      (1, encode_sprite_scaling_mode(scaling_mode)).to_json()
    Sliced(slicer) => (2, encode_texture_slicer(slicer)).to_json()
    Tiled(tiling) => (3, encode_sprite_tiling(tiling)).to_json()
  }
}

///|
fn encode_sprite(sprite : Sprite) -> Json {
  (
    encode_image_handle(sprite.image),
    sprite.texture_atlas.map(fn(texture_atlas) {
      encode_texture_atlas(texture_atlas)
    }),
    encode_color(sprite.color),
    sprite.flip_x,
    sprite.flip_y,
    sprite.custom_size.map(fn(size) { encode_vec2(size) }),
    sprite.rect.map(fn(rect) { encode_rect(rect) }),
    encode_sprite_image_mode(sprite.image_mode),
  ).to_json()
}

///|
fn encode_anchor(anchor : Anchor) -> Json {
  encode_vec2(anchor.value)
}

///|
fn encode_render_layers(layers : RenderLayers) -> Json {
  layers.mask.to_json()
}

///|
fn encode_viewport(viewport : Viewport) -> Json {
  (
    encode_ivec2(viewport.physical_position),
    encode_ivec2(viewport.physical_size),
    viewport.depth_min,
    viewport.depth_max,
  ).to_json()
}

///|
fn encode_camera_target_info(target_info : CameraTargetInfo) -> Json {
  (encode_ivec2(target_info.physical_size), target_info.scale_factor).to_json()
}

///|
fn encode_camera_computed_values(computed : CameraComputedValues) -> Json {
  (
    computed.target_info.map(fn(target_info) {
      encode_camera_target_info(target_info)
    }),
    computed.old_viewport_size.map(fn(size) { encode_ivec2(size) }),
  ).to_json()
}

///|
fn encode_clear_color_config(clear_color : ClearColorConfig) -> Json {
  match clear_color {
    Default => (0, Json::null()).to_json()
    Custom(color) => (1, encode_color(color)).to_json()
    None => (2, Json::null()).to_json()
  }
}

///|
fn encode_camera(camera : Camera) -> Json {
  (
    camera.viewport.map(fn(viewport) { encode_viewport(viewport) }),
    camera.order,
    camera.is_active,
    encode_camera_computed_values(camera.computed),
    encode_clear_color_config(camera.clear_color),
  ).to_json()
}

///|
fn encode_camera2d(_camera2d : Camera2d) -> Json {
  (0).to_json()
}

///|
fn encode_projection(projection : Projection) -> Json {
  match projection {
    Orthographic(orthographic) => (0, orthographic.scale).to_json()
  }
}

///|
fn encode_render_target(target : RenderTarget) -> Json {
  match target {
    Screen => (0, Json::null()).to_json()
    Image(image) => (1, encode_image_handle(image)).to_json()
  }
}

///|
fn encode_bloom_prefilter(prefilter : BloomPrefilter) -> Json {
  (prefilter.threshold, prefilter.threshold_softness).to_json()
}

///|
fn encode_bloom_composite_mode(mode : BloomCompositeMode) -> Json {
  match mode {
    EnergyConserving => (0).to_json()
    Additive => (1).to_json()
  }
}

///|
fn encode_bloom_settings(settings : Bloom2dSettings) -> Json {
  (
    settings.intensity,
    settings.low_frequency_boost,
    settings.low_frequency_boost_curvature,
    settings.high_pass_frequency,
    encode_bloom_prefilter(settings.prefilter),
    encode_bloom_composite_mode(settings.composite_mode),
    settings.max_mip_dimension,
    encode_vec2(settings.scale),
  ).to_json()
}

///|
fn encode_bloom2d(bloom2d : Bloom2d) -> Json {
  (
    bloom2d.source.map(fn(source) { encode_image_handle(source) }),
    bloom2d.enabled,
    encode_bloom_settings(bloom2d.settings),
  ).to_json()
}

///|
fn encode_mesh2d(mesh2d : Mesh2d) -> Json {
  encode_mesh_handle(mesh2d.mesh)
}

///|
fn encode_color_material(material : ColorMaterial) -> Json {
  encode_color_material_asset_handle(material.handle)
}

///|
fn encode_mesh_material2d(material : MeshMaterial2d) -> Json {
  encode_color_material_asset_handle(material.handle)
}

///|
fn encode_gpu_mesh2d(gpu_mesh2d : GpuMesh2d) -> Json {
  gpu_mesh2d.mesh_id.to_json()
}

///|
fn encode_visibility(visibility : @visibility.Visibility) -> Json {
  match visibility {
    @visibility.Visibility::Hidden => (0).to_json()
    @visibility.Visibility::Inherited => (1).to_json()
    @visibility.Visibility::Visible => (2).to_json()
  }
}

///|
fn encode_inherited_visibility(
  inherited_visibility : @visibility.InheritedVisibility,
) -> Json {
  inherited_visibility.is_visible().to_json()
}

///|
fn encode_view_visibility(view_visibility : @visibility.ViewVisibility) -> Json {
  view_visibility.is_visible().to_json()
}

///|
pub fn SpriteBundle::spawn_ecs(
  self : SpriteBundle,
  world : @ecs.World,
) -> @core.Entity {
  let entity = world.spawn_empty()
  ecs_set_component_json(
    world,
    entity,
    ecs_key_sprite,
    encode_sprite(self.sprite),
  )
  ecs_set_component_json(
    world,
    entity,
    ecs_key_anchor,
    encode_anchor(self.anchor),
  )
  ecs_set_component_json(
    world,
    entity,
    ecs_key_render_layers,
    encode_render_layers(self.layers),
  )
  ecs_set_component_json(
    world,
    entity,
    @visibility.ecs_key_visibility,
    encode_visibility(self.visibility),
  )
  ecs_set_component_json(
    world,
    entity,
    @visibility.ecs_key_inherited_visibility,
    encode_inherited_visibility(self.inherited_visibility),
  )
  ecs_set_component_json(
    world,
    entity,
    @visibility.ecs_key_view_visibility,
    encode_view_visibility(self.view_visibility),
  )
  try! (world.set(entity, @math.ecs_key_transform, self.transform) |> ignore)
  entity
}

///|
pub fn Camera2dBundle::spawn_ecs(
  self : Camera2dBundle,
  world : @ecs.World,
) -> @core.Entity {
  let entity = world.spawn_empty()
  ecs_set_component_json(
    world,
    entity,
    ecs_key_camera2d,
    encode_camera2d(self.camera2d),
  )
  ecs_set_component_json(
    world,
    entity,
    ecs_key_camera,
    encode_camera(self.camera),
  )
  ecs_set_component_json(
    world,
    entity,
    ecs_key_projection,
    encode_projection(self.projection),
  )
  ecs_set_component_json(
    world,
    entity,
    ecs_key_render_target,
    encode_render_target(self.target),
  )
  ecs_set_component_json(
    world,
    entity,
    ecs_key_render_layers,
    encode_render_layers(self.layers),
  )
  if self.bloom2d is Some(bloom2d) {
    ecs_set_component_json(
      world,
      entity,
      ecs_key_bloom2d,
      encode_bloom2d(bloom2d),
    )
  }
  try! (world.set(entity, @math.ecs_key_transform, self.transform) |> ignore)
  entity
}

///|
pub fn Mesh2dBundle::spawn_ecs(
  self : Mesh2dBundle,
  world : @ecs.World,
) -> @core.Entity {
  let entity = world.spawn_empty()
  ecs_set_component_json(
    world,
    entity,
    ecs_key_mesh2d,
    encode_mesh2d(self.mesh),
  )
  ecs_set_component_json(
    world,
    entity,
    ecs_key_color_material,
    encode_color_material(self.material),
  )
  ecs_set_component_json(
    world,
    entity,
    ecs_key_mesh_material2d,
    encode_mesh_material2d(MeshMaterial2d::from_color_material(self.material)),
  )
  ecs_set_component_json(
    world,
    entity,
    ecs_key_render_layers,
    encode_render_layers(self.layers),
  )
  ecs_set_component_json(
    world,
    entity,
    @visibility.ecs_key_visibility,
    encode_visibility(self.visibility),
  )
  ecs_set_component_json(
    world,
    entity,
    @visibility.ecs_key_inherited_visibility,
    encode_inherited_visibility(self.inherited_visibility),
  )
  ecs_set_component_json(
    world,
    entity,
    @visibility.ecs_key_view_visibility,
    encode_view_visibility(self.view_visibility),
  )
  try! (world.set(entity, @math.ecs_key_transform, self.transform) |> ignore)
  let mesh_id = render2d_upload_mesh_handle(self.mesh.mesh)
  ecs_set_component_json(
    world,
    entity,
    ecs_key_gpu_mesh2d,
    encode_gpu_mesh2d(GpuMesh2d::new(mesh_id)),
  )
  entity
}
