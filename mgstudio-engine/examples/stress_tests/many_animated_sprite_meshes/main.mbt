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
const GRID_HALF_X : Int = 72

///|
const GRID_HALF_Y : Int = 54

///|
const TILE_SIZE : Float = 36.0F

///|
const CAMERA_SPEED : Float = 1000.0F

///|
const ATLAS_FRAME_COUNT : Int = 7

///|
const ATLAS_FRAME_SECONDS : Float = 0.1F

///|
struct AnimationTimer {
  mut elapsed : Float
}

///|
let animation_timer_key : @ecs.ComponentKey[AnimationTimer] = @ecs.register_component(
  debug_name="examples.stress_tests.many_animated_sprite_meshes.AnimationTimer",
)

///|
pub impl @ecs.Component for AnimationTimer with component() {
  animation_timer_key
}

///|
struct AtlasFrame {
  mut index : Int
}

///|
let atlas_frame_key : @ecs.ComponentKey[AtlasFrame] = @ecs.register_component(
  debug_name="examples.stress_tests.many_animated_sprite_meshes.AtlasFrame",
)

///|
pub impl @ecs.Component for AtlasFrame with component() {
  atlas_frame_key
}

///|
struct AnimationMaterials {
  handles : Array[@asset.Handle[@sprite.ColorMaterialAsset]]
}

///|
let animation_materials_key : @ecs.ResourceKey[AnimationMaterials] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_animated_sprite_meshes.AnimationMaterials",
)

///|
impl @app.Resource for AnimationMaterials with resource() {
  animation_materials_key
}

///|
struct PrintTimer {
  mut seconds : Float
}

///|
let print_timer_key : @ecs.ResourceKey[PrintTimer] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_animated_sprite_meshes.PrintTimer",
)

///|
impl @app.Resource for PrintTimer with resource() {
  print_timer_key
}

///|
fn PrintTimer::default() -> PrintTimer {
  { seconds: 0.0F }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let texture = asset_server
    .get()
    .load("textures/rpg/chars/gabe/gabe-idle-run.png")
  let mesh = meshes.get_ref().val.add(
    @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::new(24.0F, 24.0F)).to_mesh(),
  )

  let atlas_materials : Array[@asset.Handle[@sprite.ColorMaterialAsset]] = []
  let uv_scale_x = 1.0F / float_from_int(ATLAS_FRAME_COUNT)
  for i in 0..<ATLAS_FRAME_COUNT {
    let uv_offset_x = float_from_int(i) * uv_scale_x
    let material = materials.get_ref().val.add(
      @sprite.ColorMaterialAsset::from_image(texture)
      .with_alpha_mode(@sprite.AlphaMode2d::Mask(0.5F))
      .with_uv_scale(@math.Vec2::new(uv_scale_x, 1.0F))
      .with_uv_offset(@math.Vec2::new(uv_offset_x, 0.0F)),
    )
    atlas_materials.push(material)
  }
  commands.insert_resource(AnimationMaterials::{ handles: atlas_materials })

  for y in -GRID_HALF_Y..<GRID_HALF_Y {
    for x in -GRID_HALF_X..<GRID_HALF_X {
      let idx = (y + GRID_HALF_Y) * (GRID_HALF_X * 2) + (x + GRID_HALF_X)
      let start_frame = idx % ATLAS_FRAME_COUNT
      let start_elapsed = float_from_int(idx * 17 % 100) /
        100.0F *
        ATLAS_FRAME_SECONDS
      ignore(
        commands.spawn(
          (
            @sprite.Mesh2d::new(mesh),
            @sprite.MeshMaterial2d::new(atlas_materials[start_frame]),
            @transform.Transform::from_xyz(
              float_from_int(x) * TILE_SIZE,
              float_from_int(y) * TILE_SIZE,
              float_from_int(idx % 100) / 100.0F,
            ).with_rotation(
              @math.Quat::from_rotation_z(
                float_from_int(idx % 360) * 0.017453292519943295F,
              ),
            ),
            AnimationTimer::{ elapsed: start_elapsed },
            AtlasFrame::{ index: start_frame },
          ),
        ),
      )
    }
  }
}

///|
fn animate_meshes(
  time : @app.Res[@time.Time[Unit]],
  materials : @app.Res[AnimationMaterials],
  meshes : @ecs.Query[
    (
      @ecs.Mut[AnimationTimer],
      @ecs.Mut[AtlasFrame],
      @ecs.Mut[@sprite.MeshMaterial2d[@sprite.ColorMaterialAsset]],
    ),
    @ecs.All,
  ],
) -> Unit {
  let frame_count = materials.get().handles.length()
  if frame_count == 0 {
    return
  }
  let delta_secs = time.get().delta_secs()
  try! meshes.for_each(fn(_entity, data) {
    let (timer, frame, material) = data
    let timer_ref = timer.get_ref()
    timer_ref.val.elapsed += delta_secs
    if timer_ref.val.elapsed < ATLAS_FRAME_SECONDS {
      return
    }
    let frame_ref = frame.get_ref()
    while timer_ref.val.elapsed >= ATLAS_FRAME_SECONDS {
      timer_ref.val.elapsed -= ATLAS_FRAME_SECONDS
      frame_ref.val.index = (frame_ref.val.index + 1) % frame_count
    }
    material.set(
      @sprite.MeshMaterial2d::new(materials.get().handles[frame_ref.val.index]),
    )
  })
}

///|
fn move_camera(
  time : @app.Res[@time.Time[Unit]],
  camera : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Camera2d],
  ],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  try! camera.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.rotation = @math.Quat::from_rotation_z(elapsed * 0.5F)
    transform_ref.val.translation = transform_ref.val.translation.add(
      @math.Vec3::new(CAMERA_SPEED * time.get().delta_secs(), 0.0F, 0.0F),
    )
  })
}

///|
fn print_count(
  time : @app.Res[@time.Time[Unit]],
  timer : @app.ResMut[PrintTimer],
  meshes : @ecs.Query[@ecs.Comp[AtlasFrame], @ecs.All],
) -> Unit {
  let timer_ref = timer.get_ref()
  timer_ref.val.seconds += time.get().delta_secs()
  if timer_ref.val.seconds < 1.0F {
    return
  }
  timer_ref.val.seconds -= 1.0F
  println("Animated sprite meshes: \{meshes.count()}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(PrintTimer::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(animate_meshes)))
  .add_systems(@app.Update, @app.system(@app.system_param2(move_camera)))
  .add_systems(@app.Update, @app.system(@app.system_param3(print_count)))
  .run()
}
