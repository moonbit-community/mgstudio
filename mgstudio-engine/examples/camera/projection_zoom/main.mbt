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
/// Port of `bevy/examples/camera/projection_zoom.rs`.

///|
priv struct CameraSettings {
  orthographic_viewport_height : Float
  orthographic_zoom_max : Float
  orthographic_zoom_min : Float
  orthographic_zoom_speed : Float
  perspective_zoom_max : Float
  perspective_zoom_min : Float
  perspective_zoom_speed : Float
}

///|
let camera_settings_resource_key : @ecs.ResourceKey[CameraSettings] = @ecs.register_resource(
  debug_name="examples.camera.projection_zoom.CameraSettings",
)

///|
impl @app.Resource for CameraSettings with resource() {
  camera_settings_resource_key
}

///|
fn CameraSettings::default() -> CameraSettings {
  {
    orthographic_viewport_height: 5.0F,
    orthographic_zoom_max: 10.0F,
    orthographic_zoom_min: 0.1F,
    orthographic_zoom_speed: 0.2F,
    perspective_zoom_max: @math.pi() - 0.2F,
    perspective_zoom_min: @math.pi() / 5.0F,
    perspective_zoom_speed: 0.05F,
  }
}

///|
fn spawn_ui_text_handle(
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @sprite.Color,
) -> @text.TextHandle {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(font_size),
    @transform.Transform::identity(),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .spawn()
}

///|
fn setup(
  asset_server : @app.Res[@asset.AssetServer],
  camera_settings : @app.Res[CameraSettings],
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let settings = camera_settings.get()

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Camera"),
        @camera.Camera3d::default(),
        @camera.Projection::Orthographic(@camera.OrthographicProjection3d::{
          ..@camera.OrthographicProjection3d::default_3d(),
          scaling_mode: @camera.OrthographicScalingMode3d::FixedVertical(
            settings.orthographic_viewport_height,
          ),
          scale: 1.0F,
        }),
        @transform.Transform::from_xyz(5.0F, 5.0F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Plane"),
        @pbr.Mesh3d::new(
          meshes.get_ref().val.add(
            @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(5.0F, 5.0F)),
          ),
        ),
        @pbr.MeshMaterial3d::new(
          materials.get_ref().val.add(
            @pbr.StandardMaterial::from_color(
              @sprite.Color::srgb(0.3F, 0.5F, 0.3F),
            ).with_cull_mode(None),
          ),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Fox"),
        @scene.SceneRoot::new(
          asset_server
          .get()
          .load(
            @gltf.GltfAssetLabel::Scene(0).from_asset("models/animated/Fox.glb"),
          ),
        ),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(0.025F)),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Light"),
        @pbr.PointLight::default(),
        @transform.Transform::from_xyz(3.0F, 8.0F, 5.0F),
      ),
    ),
  )
}

///|
fn instructions(
  asset_server : @app.Res[@asset.AssetServer],
  commands : @app.Commands,
) -> Unit {
  let text_handle = spawn_ui_text_handle(
    "Scroll mouse wheel to zoom in/out\nSpace: switch between orthographic and perspective projections",
    asset_server.get().load_font("fonts/FiraSans-Bold.ttf"),
    20.0F,
    @sprite.Color::white(),
  )
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Instructions"),
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
        @ui.UiText::new(text_handle),
      ),
    ),
  )
}

///|
fn switch_projection(
  camera_query : @ecs.Query1Filtered[
    @camera.Projection,
    @ecs.With[@camera.Camera3d],
  ],
  camera_settings : @app.Res[CameraSettings],
  keyboard_input : @input.ButtonInput[@window.KeyCode],
) -> Unit {
  if !keyboard_input.just_pressed(@window.KeyCode::Space) {
    return
  }
  let settings = camera_settings.get()
  try! camera_query.view_mut(fn(_entity, camera_projection) {
    let projection_ref = camera_projection.get_ref()
    let next_projection = match projection_ref.val {
      @camera.Projection::Orthographic(_) =>
        Some(
          @camera.Projection::Perspective(@camera.PerspectiveProjection3d::{
            ..@camera.PerspectiveProjection3d::default(),
            fov: settings.perspective_zoom_min,
          }),
        )
      @camera.Projection::Perspective(_) =>
        Some(
          @camera.Projection::Orthographic(@camera.OrthographicProjection3d::{
            ..@camera.OrthographicProjection3d::default_3d(),
            scaling_mode: @camera.OrthographicScalingMode3d::FixedVertical(
              settings.orthographic_viewport_height,
            ),
            scale: 1.0F,
          }),
        )
      @camera.Projection::Custom(_) => None
    }
    guard next_projection is Some(next_projection) else { return }
    projection_ref.val = next_projection
    camera_projection.set_changed()
  })
}

///|
fn zoom(
  camera_query : @ecs.Query1Filtered[
    @camera.Projection,
    @ecs.With[@camera.Camera3d],
  ],
  camera_settings : @app.Res[CameraSettings],
  mouse_scroll : @app.Res[@input.AccumulatedMouseScroll],
) -> Unit {
  let scroll_delta = mouse_scroll.get().delta.y
  if scroll_delta == 0.0F {
    return
  }

  let settings = camera_settings.get()
  try! camera_query.view_mut(fn(_entity, camera_projection) {
    let projection_ref = camera_projection.get_ref()
    match projection_ref.val {
      @camera.Projection::Orthographic(orthographic) => {
        let delta_zoom = -scroll_delta * settings.orthographic_zoom_speed
        let multiplicative_zoom = 1.0F + delta_zoom
        orthographic.scale = clamp_float(
          orthographic.scale * multiplicative_zoom,
          settings.orthographic_zoom_min,
          settings.orthographic_zoom_max,
        )
      }
      @camera.Projection::Perspective(perspective) => {
        let delta_zoom = -scroll_delta * settings.perspective_zoom_speed
        perspective.fov = clamp_float(
          perspective.fov + delta_zoom,
          settings.perspective_zoom_min,
          settings.perspective_zoom_max,
        )
      }
      @camera.Projection::Custom(_) => return
    }
    camera_projection.set_changed()
  })
}

///|
fn clamp_float(value : Float, lower : Float, upper : Float) -> Float {
  if value < lower {
    return lower
  }
  if value > upper {
    return upper
  }
  value
}

///|
fn main {
  let setup_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param5(setup),
  )
  let instructions_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(instructions),
  )
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .init_resource(CameraSettings::default)
  .add_systems(
    @app.Startup,
    (setup_system, instructions_system) |> @app.chain(),
  )
  .add_systems(@app.Update, @app.system(@app.system_param3(switch_projection)))
  .add_systems(@app.Update, @app.system(@app.system_param3(zoom)))
  .run()
}
