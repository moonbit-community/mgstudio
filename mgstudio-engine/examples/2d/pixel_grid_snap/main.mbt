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
pub impl @ecs.Component for Canvas with fn component() {
  canvas_key
}

///|
struct InGameCamera {}

///|
let in_game_camera_key : @ecs.ComponentKey[InGameCamera] = @ecs.register_component(
  debug_name="examples.2d.pixel_grid_snap.InGameCamera",
)

///|
pub impl @ecs.Component for InGameCamera with fn component() {
  in_game_camera_key
}

///|
struct OuterCamera {}

///|
let outer_camera_key : @ecs.ComponentKey[OuterCamera] = @ecs.register_component(
  debug_name="examples.2d.pixel_grid_snap.OuterCamera",
)

///|
pub impl @ecs.Component for OuterCamera with fn component() {
  outer_camera_key
}

///|
struct Rotate {}

///|
let rotate_key : @ecs.ComponentKey[Rotate] = @ecs.register_component(
  debug_name="examples.2d.pixel_grid_snap.Rotate",
)

///|
pub impl @ecs.Component for Rotate with fn component() {
  rotate_key
}

///|
fn pixel_perfect_layers() -> @camera_render_layers.RenderLayers {
  @camera_render_layers.RenderLayers::layer(PIXEL_PERFECT_LAYER)
}

///|
fn high_res_layers() -> @camera_render_layers.RenderLayers {
  @camera_render_layers.RenderLayers::layer(HIGH_RES_LAYER)
}

///|
fn main {
  let setup_camera_system : @app.SystemConfig[@ecs.World] = @app.system_config_param2(
    setup_camera,
  )
  let setup_sprite_system : @app.SystemConfig[@ecs.World] = @app.system_config_param2(
    setup_sprite,
  )
  let setup_mesh_system : @app.SystemConfig[@ecs.World] = @app.system_config_param3(
    setup_mesh,
  )
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::set(@asset.AssetPlugin::nearest()))
  .add_systems(
    Startup,
    (setup_camera_system, setup_sprite_system, setup_mesh_system)
    |> @app.chain(),
  )
  .add_systems_param2(Update, rotate)
  .add_systems_param2(Update, fit_canvas)
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
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[
    @asset.Assets[@sprite_render_mesh2d_color_material.ColorMaterial],
  ],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(
          @mesh_primitives.add_mesh(meshes.peek(), @math.Capsule2d::Capsule2d()),
        ),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite_render_mesh2d_color_material.ColorMaterial::from_color(
              @color.Color::black(),
            ),
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
fn setup_camera(
  commands : @app.Commands,
  images : @app.ResMut[@asset.Assets[@asset.Image]],
) -> Unit {
  let image_handle = images.modify(fn(images) {
    images.add(
      @asset.Image::new_target_texture(
        RES_WIDTH,
        RES_HEIGHT,
        Bgra8UnormSrgb,
        None,
      ),
    )
  })

  ignore(
    commands.spawn(
      (
        @camera_components2d.Camera2d::Camera2d(),
        @camera_camera.Camera::Camera()
        .with_order(-1)
        .with_clear_color(
          @color.Color::srgba(0.5019608F, 0.5019608F, 0.5019608F, 1.0F),
        ),
        @camera_camera.RenderTarget::Image(image_handle),
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
      (
        @camera_components2d.Camera2d::Camera2d(),
        OuterCamera::{  },
        high_res_layers(),
      ),
    ),
  )
}

///|
fn rotate(
  time : @app.Res[@time.Time[Unit]],
  transforms : @ecs.Query[@ecs.Write[@transform.Transform], @ecs.With[Rotate]],
) -> Unit {
  try! transforms.for_each(fn(_entity, transform) {
    transform.modify(fn(value) { value.rotate_z(time.get().delta_secs()) })
  })
}

///|
fn fit_canvas(
  resize_messages : @ecs.MessageReader[@window.WindowResized],
  projection_query : @ecs.Query[
    @ecs.Write[@camera_projection2d.Projection],
    @ecs.With[OuterCamera],
  ],
) -> Unit {
  for window_resized in resize_messages.read() {
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
    try! projection_query.view(fn(_entity, projection) {
      match projection.value() {
        Orthographic(current) =>
          projection.set(Orthographic(current.with_scale(projection_scale)))
      }
    })
  }
}
