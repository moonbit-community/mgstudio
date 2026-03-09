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
fn orthographic_projection(settings : CameraSettings) -> @render3d.Projection {
  @render3d.Projection::Orthographic(
    @render3d.OrthographicProjection3d::default()
    .with_scaling_mode(
      @render3d.OrthographicScalingMode3d::FixedVertical(
        settings.orthographic_viewport_height,
      ),
    )
    .with_scale(1.0F),
  )
}

///|
fn perspective_projection(settings : CameraSettings) -> @render3d.Projection {
  @render3d.Projection::Perspective(
    @render3d.PerspectiveProjection3d::default().with_fov(
      settings.perspective_zoom_min,
    ),
  )
}

///|
fn setup(
  asset_server : @app.Res[@asset.AssetServer],
  camera_settings : @app.Res[CameraSettings],
  materials : @app.ResMut[@asset.Assets[@render3d.StandardMaterial]],
) -> Unit {
  let world = @app.current_world().unwrap()
  let tick = world.read_change_tick()
  let settings = camera_settings.get()

  let camera = @render3d.Camera3dBundle::new_with_projection(
    @render2d.Camera::default(),
    orthographic_projection(settings),
    @math.Transform::from_xyz(5.0F, 5.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@ecs.Name::component())
  .insert(camera, @ecs.Name::new("Camera"), tick)

  let material_handle = materials.get_ref().val.add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::srgb(0.3F, 0.5F, 0.3F),
    ).with_cull_mode(None),
  )
  let plane = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(5.0F, 5.0F),
    @render3d.MeshMaterial3d::new(material_handle),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@ecs.Name::component())
  .insert(plane, @ecs.Name::new("Plane"), tick)

  let fox = world.spawn_empty()
  world
  .component(@ecs.Name::component())
  .insert(fox, @ecs.Name::new("Fox"), tick)
  world
  .component(@scene.SceneRoot::component())
  .insert(
    fox,
    @scene.SceneRoot::new(
      asset_server
      .get()
      .load(
        @scene.GltfAssetLabel::Scene(0).from_asset("models/animated/Fox.glb"),
      ),
    ),
    tick,
  )
  world
  .component(@math.Transform::component())
  .insert(
    fox,
    @math.Transform::identity().with_scale(@math.Vec3::splat(0.025F)),
    tick,
  )

  let light = world.spawn_empty()
  world
  .component(@ecs.Name::component())
  .insert(light, @ecs.Name::new("Light"), tick)
  world
  .component(@render3d.PointLight::component())
  .insert(light, @render3d.PointLight::default(), tick)
  world
  .component(@math.Transform::component())
  .insert(light, @math.Transform::from_xyz(3.0F, 8.0F, 5.0F), tick)
}

///|
fn instructions(asset_server : @app.Res[@asset.AssetServer]) -> Unit {
  let world = @app.current_world().unwrap()
  let tick = world.read_change_tick()
  let overlay_camera = @render2d.Camera2dBundle::new(
    @render2d.Camera::default().with_order(1).with_clear_color_none(),
    @math.Transform::identity(),
  ).spawn(world)
  world
  .component(@ui.IsDefaultUiCamera::component())
  .insert(overlay_camera, @ui.IsDefaultUiCamera::default(), tick)

  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )

  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new(
        "Scroll mouse wheel to zoom in/out\nSpace: switch between orthographic and perspective projections",
      ),
      @text.TextFont::default()
      .with_font(asset_server.get().load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(20.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@render2d.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let text_entity = world.spawn_empty()
  world
  .component(@ecs.Name::component())
  .insert(text_entity, @ecs.Name::new("Instructions"), tick)
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn switch_projection(
  camera_query : @ecs.Query1Filtered[
    @render3d.Projection,
    @ecs.With[@render3d.Camera3d],
  ],
  camera_settings : @app.Res[CameraSettings],
  keyboard_input : @input.ButtonInput[@window.KeyCode],
) -> Unit {
  if !keyboard_input.just_pressed(Space) {
    return
  }
  let settings = camera_settings.get()
  try! camera_query.view_mut(fn(_entity, camera_projection) {
    let projection_ref = camera_projection.get_ref()
    let next_projection = match projection_ref.val {
      @render3d.Projection::Orthographic(_) =>
        Some(perspective_projection(settings))
      @render3d.Projection::Perspective(_) =>
        Some(orthographic_projection(settings))
      @render3d.Projection::Custom(_) => None
    }
    guard next_projection is Some(next_projection) else { return }
    projection_ref.val = next_projection
    camera_projection.set_changed()
  })
}

///|
fn zoom(
  camera_query : @ecs.Query1Filtered[
    @render3d.Projection,
    @ecs.With[@render3d.Camera3d],
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
    let next_projection = match projection_ref.val {
      @render3d.Projection::Orthographic(orthographic) => {
        let delta_zoom = -scroll_delta * settings.orthographic_zoom_speed
        let multiplicative_zoom = 1.0F + delta_zoom
        let next_scale = clamp_float(
          orthographic.scale() * multiplicative_zoom,
          settings.orthographic_zoom_min,
          settings.orthographic_zoom_max,
        )
        @render3d.Projection::Orthographic(orthographic.with_scale(next_scale))
      }
      @render3d.Projection::Perspective(perspective) => {
        let delta_zoom = -scroll_delta * settings.perspective_zoom_speed
        let next_fov = clamp_float(
          perspective.fov() + delta_zoom,
          settings.perspective_zoom_min,
          settings.perspective_zoom_max,
        )
        @render3d.Projection::Perspective(perspective.with_fov(next_fov))
      }
      @render3d.Projection::Custom(_) => return
    }
    projection_ref.val = next_projection
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
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .init_resource(CameraSettings::default)
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Startup, @app.system(@app.system_param(instructions)))
  .add_systems(@app.Update, @app.system(@app.system_param3(switch_projection)))
  .add_systems(@app.Update, @app.system(@app.system_param3(zoom)))
  .run()
}
