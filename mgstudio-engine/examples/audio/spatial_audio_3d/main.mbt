// Copyright 2026 International Digital Economy Academy
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

///|
const PI : Float = 3.141592653589793F

///|
const LISTENER_GAP : Float = 4.0F

///|
const LISTENER_SPEED : Float = 2.0F

///|
const EMITTER_RADIUS : Float = 0.2F

///|
const EAR_SIZE : Float = 0.2F

///|
const ORBIT_RADIUS : Float = 3.0F

///|
const UV_SPHERE_STACKS : Int = 18

///|
const UV_SPHERE_SECTORS : Int = 32

///|
priv struct SpatialAudio3dState {
  mut emitter : @core.Entity
  mut listener : @core.Entity
  mut emitter_stopwatch : @time.Stopwatch
}

///|
let spatial_audio_3d_state : Ref[SpatialAudio3dState] = Ref::new({
  emitter: @core.Entity::placeholder(),
  listener: @core.Entity::placeholder(),
  emitter_stopwatch: @time.Stopwatch::new(),
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(update_positions))
  .add_systems(@app.Update, @app.system(update_listener))
  .add_systems(@app.Update, @app.system(mute))
  .run()
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn color_blue() -> @sprite.Color {
  @sprite.Color::srgb(0.0F, 0.0F, 1.0F)
}

///|
fn color_red() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 0.0F, 0.0F)
}

///|
fn color_lime() -> @sprite.Color {
  @sprite.Color::srgb(0.0F, 1.0F, 0.0F)
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in spatial_audio_3d example")
  }
}

///|
fn tick_delta(world : @ecs.World) -> @core.Duration {
  world_time(world).delta()
}

///|
fn toggle_stopwatch(stopwatch : @time.Stopwatch) -> @time.Stopwatch {
  if stopwatch.is_paused() {
    stopwatch.unpause()
  } else {
    stopwatch.pause()
  }
}

///|
fn uv_sphere_mesh(radius : Float, stacks : Int, sectors : Int) -> @pbr.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(stacks)
  let sectors_f = float_from_int(sectors)
  let stack_step = PI / stacks_f
  let sector_step = 2.0F * PI / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = PI / 2.0F - float_from_int(i) * stack_step
    let ring_radius = radius * @math.cos(stack_angle)
    let y = radius * @math.sin(stack_angle)
    for j in 0..<(sectors + 1) {
      let sector_angle = float_from_int(j) * sector_step
      let x = ring_radius * @math.cos(sector_angle)
      let z = ring_radius * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      uvs.push(
        @math.Vec2::new(
          float_from_int(j) / sectors_f,
          float_from_int(i) / stacks_f,
        ),
      )
    }
  }

  let row = sectors + 1
  for i in 0..<stacks {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<sectors {
      if i != 0 {
        indices.push(k1 + j)
        indices.push(k2 + j)
        indices.push(k1 + j + 1)
      }
      if i != stacks - 1 {
        indices.push(k1 + j + 1)
        indices.push(k2 + j)
        indices.push(k2 + j + 1)
      }
    }
  }

  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn spawn_ui_overlay(world : @ecs.World, content : String) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  let text_entity = world.spawn_empty()
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(20.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(20.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
}

///|
fn spawn_mesh(
  world : @ecs.World,
  mesh : @pbr.Mesh3d,
  color : @sprite.Color,
  transform : @transform.Transform,
) -> @core.Entity {
  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(color),
  )
  @pbr.MeshMaterial3dBundle::new(
    mesh,
    @pbr.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
}

///|
fn spawn_listener_ear(
  world : @ecs.World,
  listener : @core.Entity,
  offset : @math.Vec3,
  color : @sprite.Color,
) -> Unit {
  let ear = spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(EAR_SIZE, EAR_SIZE, EAR_SIZE),
        ),
      ),
    ),
    color,
    @transform.Transform::from_xyz(offset.x, offset.y, offset.z),
  )
  try! world.set_by_key(
    ear,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(listener),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  spatial_audio_3d_state.val = {
    emitter: @core.Entity::placeholder(),
    listener: @core.Entity::placeholder(),
    emitter_stopwatch: @time.Stopwatch::new(),
  }

  let asset_server = @asset.AssetServer::new()
  let track : @asset.Handle[@audio.AudioSource] = asset_server.load(
    "sounds/Windless Slopes.ogg",
  )
  let emitter = spawn_mesh(
    world,
    uv_sphere_mesh(EMITTER_RADIUS, UV_SPHERE_STACKS, UV_SPHERE_SECTORS),
    color_blue(),
    @transform.Transform::identity(),
  )

  try! world.set_by_key(
    emitter,
    @audio.ecs_key_audio_source_player,
    @audio.AudioPlayer::new(track),
  )
  try! world.set_by_key(
    emitter,
    @audio.ecs_key_playback_settings,
    @audio.PlaybackSettings::looped().with_spatial(true),
  )

  let listener = world.spawn_empty()
  let listener_component = @audio.SpatialListener::new(LISTENER_GAP)
  try! world.set_by_key(
    listener,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
  try! world.set_by_key(
    listener, @audio.ecs_key_spatial_listener, listener_component,
  )

  spawn_listener_ear(
    world,
    listener,
    listener_component.left_ear_offset,
    color_red(),
  )
  spawn_listener_ear(
    world,
    listener,
    listener_component.right_ear_offset,
    color_lime(),
  )

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::default(),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )

  spawn_ui_overlay(
    world, "Up/Down/Left/Right: Move Listener\nSpace: Toggle Emitter Movement\nM: Toggle Mute",
  )

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 5.0F, 5.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  spatial_audio_3d_state.val.emitter = emitter
  spatial_audio_3d_state.val.listener = listener
}

///|
fn update_positions(world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Space) {
    spatial_audio_3d_state.val.emitter_stopwatch = toggle_stopwatch(
      spatial_audio_3d_state.val.emitter_stopwatch,
    )
  }

  spatial_audio_3d_state.val.emitter_stopwatch = spatial_audio_3d_state.val.emitter_stopwatch.tick(
    tick_delta(world),
  )

  if spatial_audio_3d_state.val.emitter_stopwatch.is_paused() {
    return
  }

  let elapsed = spatial_audio_3d_state.val.emitter_stopwatch.elapsed_secs()
  let next_x = @math.sin(elapsed) * ORBIT_RADIUS
  let next_z = @math.cos(elapsed) * ORBIT_RADIUS
  try! (world.update_by_key(
    spatial_audio_3d_state.val.emitter,
    @transform.ecs_key_transform,
    fn(transform : @transform.Transform) {
      transform.with_translation(@math.Vec3::new(next_x, 0.0F, next_z))
    },
  )
  |> ignore)
}

///|
fn update_listener(world : @ecs.World) -> Unit {
  let delta = LISTENER_SPEED * world_time(world).delta_seconds()
  let dx = if @input.key_pressed(@window.KeyCode::ArrowRight) {
    delta
  } else if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    -delta
  } else {
    0.0F
  }
  let dz = if @input.key_pressed(@window.KeyCode::ArrowDown) {
    delta
  } else if @input.key_pressed(@window.KeyCode::ArrowUp) {
    -delta
  } else {
    0.0F
  }

  if dx == 0.0F && dz == 0.0F {
    return
  }

  try! (world.update_by_key(
    spatial_audio_3d_state.val.listener,
    @transform.ecs_key_transform,
    fn(transform : @transform.Transform) {
      let translation = transform.translation
      transform.with_translation(
        @math.Vec3::new(translation.x + dx, translation.y, translation.z + dz),
      )
    },
  )
  |> ignore)
}

///|
fn mute(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::KeyM) {
    return
  }

  let entities : Array[@core.Entity] = []
  world.for_each_component(@audio.ecs_key_spatial_audio_sink, fn(
    entity : @core.Entity,
    _sink : @audio.SpatialAudioSink,
  ) {
    entities.push(entity)
  })

  if entities.length() == 0 {
    return
  }

  for entity in entities {
    try! (world.update_by_key(entity, @audio.ecs_key_spatial_audio_sink, fn(
      sink : @audio.SpatialAudioSink,
    ) {
      sink.toggle_mute()
    })
    |> ignore)
  }
}
