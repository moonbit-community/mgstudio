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
const RES_WIDTH : Int = 160

///|
const RES_HEIGHT : Int = 90

///|
const PIXEL_PERFECT_LAYER : Int = 0

///|
const HIGH_RES_LAYER : Int = 1

///|
struct Canvas {}

///|
let canvas_key : @ecs.ComponentKey[Canvas] = @ecs.register_component(
  debug_name="examples.2d.pixel_grid_snap.Canvas",
)

///|
pub impl @ecs.Component for Canvas with component() {
  canvas_key
}

///|
struct InGameCamera {}

///|
let in_game_camera_key : @ecs.ComponentKey[InGameCamera] = @ecs.register_component(
  debug_name="examples.2d.pixel_grid_snap.InGameCamera",
)

///|
pub impl @ecs.Component for InGameCamera with component() {
  in_game_camera_key
}

///|
struct OuterCamera {}

///|
let outer_camera_key : @ecs.ComponentKey[OuterCamera] = @ecs.register_component(
  debug_name="examples.2d.pixel_grid_snap.OuterCamera",
)

///|
pub impl @ecs.Component for OuterCamera with component() {
  outer_camera_key
}

///|
struct Rotate {}

///|
let rotate_key : @ecs.ComponentKey[Rotate] = @ecs.register_component(
  debug_name="examples.2d.pixel_grid_snap.Rotate",
)

///|
pub impl @ecs.Component for Rotate with component() {
  rotate_key
}

///|
fn pixel_perfect_layers() -> @sprite.RenderLayers {
  @sprite.RenderLayers::layer(PIXEL_PERFECT_LAYER)
}

///|
fn high_res_layers() -> @sprite.RenderLayers {
  @sprite.RenderLayers::layer(HIGH_RES_LAYER)
}

///|
fn main {
  let setup_camera_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param(setup_camera),
  )
  let setup_sprite_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(setup_sprite),
  )
  let setup_mesh_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(setup_mesh),
  )
  @app.App::new(@ecs.World::new())
  .add_plugin_group(fn() {
    @mgstudio.DefaultPlugins::set(@asset.AssetPlugin::default_nearest())
  })
  .add_systems(
    @app.Startup,
    (setup_camera_system, setup_sprite_system, setup_mesh_system)
    |> @app.chain(),
  )
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate)))
  .add_systems(@app.Update, @app.system(@app.system_param2(fit_canvas)))
  .run()
}

///|
fn setup_sprite(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(
          asset_server.get().load("pixel/bevy_pixel_dark.png"),
        ),
        @transform.Transform::from_xyz(-45.0F, 20.0F, 2.0F),
        Rotate::{  },
        pixel_perfect_layers(),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(
          asset_server.get().load("pixel/bevy_pixel_light.png"),
        ),
        @transform.Transform::from_xyz(-45.0F, -20.0F, 2.0F),
        Rotate::{  },
        high_res_layers(),
      ),
    ),
  )
}

///|
fn setup_mesh(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@sprite.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(
          meshes.get_ref().val.add(
            @sprite.mesh2d_geometry_capsule(@sprite.Capsule2d::default()).to_mesh(),
          ),
        ),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val.add(
            @sprite.ColorMaterialAsset::from_color(@sprite.Color::black()),
          ),
        ),
        @transform.Transform::from_xyz(25.0F, 0.0F, 2.0F).with_scale(
          @math.Vec3::splat(32.0F),
        ),
        Rotate::{  },
        pixel_perfect_layers(),
      ),
    ),
  )
}

///|
fn setup_camera(commands : @app.Commands) -> Unit {
  let image_handle = @sprite_render.render2d_create_render_target_ecs(
    RES_WIDTH,
    RES_HEIGHT,
    true,
  )

  ignore(
    commands.spawn(
      (
        @sprite.Camera2d::default(),
        @sprite.Camera::default()
        .with_order(-1)
        .with_clear_color(@sprite.Color::srgb(0.5F, 0.5F, 0.5F)),
        @sprite.RenderTarget::Image(image_handle),
        InGameCamera::{  },
        pixel_perfect_layers(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(image_handle),
        Canvas::{  },
        high_res_layers(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (@sprite.Camera2d::default(), OuterCamera::{  }, high_res_layers()),
    ),
  )
}

///|
fn rotate(
  time : @app.Res[@time.Time[Unit]],
  transforms : @ecs.Query1Filtered[@transform.Transform, @ecs.With[Rotate]],
) -> Unit {
  try! transforms.for_each(fn(_entity, transform) {
    transform.rotate_z(time.get().delta_secs())
  })
}

///|
fn fit_canvas(
  resize_messages : @ecs.MessageReader[@window.WindowResized],
  projection_query : @ecs.Query1Filtered[
    @sprite.Projection,
    @ecs.With[OuterCamera],
  ],
) -> Unit {
  for window_resized in (try! resize_messages.read()) {
    let h_scale = window_resized.width /
      Float::from_double(RES_WIDTH.to_double())
    let v_scale = window_resized.height /
      Float::from_double(RES_HEIGHT.to_double())
    let min_scale = if h_scale < v_scale { h_scale } else { v_scale }
    let rounded_scale = min_scale.round()
    if rounded_scale <= 0.0F {
      continue
    }
    let projection_scale = 1.0F / rounded_scale
    try! projection_query.view_mut(fn(_entity, projection) {
      let projection_ref = projection.get_ref()
      match projection_ref.val {
        Orthographic(current) =>
          projection_ref.val = Orthographic(
            current.with_scale(projection_scale),
          )
      }
    })
  }
}
