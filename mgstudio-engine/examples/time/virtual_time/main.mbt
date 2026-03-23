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
/// Port of `bevy/examples/time/virtual_time.rs`.

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn get_sprite_translation_x(elapsed : Float) -> Float {
  @math.sin(elapsed) * 500.0F
}

///|
priv struct VirtualTimeState {
  mut real_text : @text.TextHandle?
  mut virtual_text : @text.TextHandle?
}

///|
let virtual_time_state : Ref[VirtualTimeState] = Ref::new({
  real_text: None,
  virtual_text: None,
})

///|
struct RealTime {}

///|
let real_time_component_key : @ecs.ComponentKey[RealTime] = @ecs.register_component(
  debug_name="examples.time.virtual_time.RealTime",
)

///|
impl @ecs.Component for RealTime with component() {
  real_time_component_key
}

///|
struct VirtualTime {}

///|
let virtual_time_component_key : @ecs.ComponentKey[VirtualTime] = @ecs.register_component(
  debug_name="examples.time.virtual_time.VirtualTime",
)

///|
impl @ecs.Component for VirtualTime with component() {
  virtual_time_component_key
}

///|
fn read_real_time(world : @ecs.World) -> @time.Time[@time.Real] {
  let real_time = try! world.get_resource(@time.real_time_resource_key())
  match real_time {
    Some(real_time) => real_time
    None => abort("Missing Time<Real> resource in virtual_time example")
  }
}

///|
fn read_virtual_time(world : @ecs.World) -> @time.Time[@time.Virtual] {
  let virtual_time = try! world.get_resource(@time.virtual_time_resource_key())
  match virtual_time {
    Some(virtual_time) => virtual_time
    None => abort("Missing Time<Virtual> resource in virtual_time example")
  }
}

///|
fn update_virtual_time_resource(
  world : @ecs.World,
  update : (@time.Time[@time.Virtual]) -> @time.Time[@time.Virtual],
) -> Unit {
  let sequence = world.advance_sequence()
  let virtual_ref = try! world
    .get_resource_ref_mut(@time.virtual_time_resource_key(), sequence)
    .unwrap()
  let time_ref = try! world
    .get_resource_ref_mut(@time.default_time_resource_key(), sequence)
    .unwrap()
  let next_virtual = update(virtual_ref.val)
  virtual_ref.val = next_virtual
  time_ref.val = next_virtual.as_generic()
}

///|
fn update_info_text(world : @ecs.World) -> Unit {
  let real_time = read_real_time(world)
  let virtual_time = read_virtual_time(world)
  if virtual_time_state.val.real_text is Some(real_text) {
    @text.text_set_content(
      real_text,
      "REAL TIME\nElapsed: " +
      real_time.elapsed_seconds().to_string() +
      "\nDelta: " +
      real_time.delta_seconds().to_string() +
      "\n",
    )
  }
  if virtual_time_state.val.virtual_text is Some(virtual_text) {
    @text.text_set_content(
      virtual_text,
      "VIRTUAL TIME\nElapsed: " +
      virtual_time.elapsed_seconds().to_string() +
      "\nDelta: " +
      virtual_time.delta_seconds().to_string() +
      "\nSpeed: " +
      virtual_time.relative_speed().to_string(),
    )
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_sequence()
  virtual_time_state.val = { real_text: None, virtual_text: None }

  update_virtual_time_resource(world, fn(
    virtual_time : @time.Time[@time.Virtual],
  ) {
    virtual_time.set_relative_speed(2.0F).unpause()
  })

  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let real_sprite = @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(texture).with_custom_size(
      Some(@math.Vec2::new(256.0F, 256.0F)),
    ),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(0.5F, 0.5F),
    ),
  ).spawn(world)
  world
  .component(RealTime::component())
  .insert(real_sprite, RealTime::{  }, tick)

  let virtual_sprite = @sprite.SpriteBundle::new(
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(1.0F, 0.843F, 0.0F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(256.0F, 256.0F))),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -160.0F),
      0.0F,
      @math.Vec2::new(0.5F, 0.5F),
    ),
  ).spawn(world)
  world
  .component(VirtualTime::component())
  .insert(virtual_sprite, VirtualTime::{  }, tick)

  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let real_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(24.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(260.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  virtual_time_state.val.real_text = Some(real_text)

  @text.Text2dBundle::new(
    @text.Text2d::new("CONTROLS\n(Un)pause: Space\nSpeed+: Up\nSpeed-: Down"),
    @text.TextFont::default().with_font(font).with_font_size(24.0F),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 320.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=50.0F,
    ),
  )
  .with_anchor(@sprite.Anchor::top_center())
  .with_bounds(@text.TextBounds::new_horizontal(300.0F))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .with_color(
    @text.TextColor::new(@sprite.Color::new(0.85F, 0.85F, 0.85F, 1.0F)),
  )
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore

  let virtual_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(24.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_right())
    .with_bounds(@text.TextBounds::new_horizontal(260.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Right))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(1.0F, 0.843F, 0.0F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  virtual_time_state.val.virtual_text = Some(virtual_text)

  update_info_text(world)
}

///|
fn input_toggle_pressed(_world : @ecs.World) -> Bool {
  @input.key_just_pressed(@window.KeyCode::Space)
}

///|
fn input_speed_up_pressed(_world : @ecs.World) -> Bool {
  @input.key_just_pressed(@window.KeyCode::ArrowUp)
}

///|
fn input_speed_down_pressed(_world : @ecs.World) -> Bool {
  @input.key_just_pressed(@window.KeyCode::ArrowDown)
}

///|
fn toggle_pause(world : @ecs.World) -> Unit {
  update_virtual_time_resource(world, fn(
    virtual_time : @time.Time[@time.Virtual],
  ) {
    virtual_time.toggle()
  })
}

///|
fn change_time_speed(world : @ecs.World, delta : Float) -> Unit {
  let virtual_time = read_virtual_time(world)
  let next_speed = clampf(
    (virtual_time.relative_speed() + delta).round(),
    0.25F,
    5.0F,
  )
  update_virtual_time_resource(world, fn(
    virtual_time : @time.Time[@time.Virtual],
  ) {
    virtual_time.set_relative_speed(next_speed)
  })
}

///|
fn change_time_speed_up(world : @ecs.World) -> Unit {
  change_time_speed(world, 1.0F)
}

///|
fn change_time_speed_down(world : @ecs.World) -> Unit {
  change_time_speed(world, -1.0F)
}

///|
fn move_real_time_sprites(
  sprite_query : @ecs.Query2RefMutFiltered[
    RealTime,
    @transform.Transform,
    @ecs.With[@sprite.Sprite],
  ],
  time : @app.Res[@time.Time[@time.Real]],
) -> Unit {
  try! sprite_query.view_mut(fn(_entity, _real_time, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.translation.x = get_sprite_translation_x(
      time.get().elapsed_secs(),
    )
  })
}

///|
fn move_virtual_time_sprites(
  sprite_query : @ecs.Query2RefMutFiltered[
    VirtualTime,
    @transform.Transform,
    @ecs.With[@sprite.Sprite],
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  try! sprite_query.view_mut(fn(_entity, _virtual_time, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.translation.x = get_sprite_translation_x(
      time.get().elapsed_secs(),
    )
  })
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(move_virtual_time_sprites)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(move_real_time_sprites)),
  )
  .add_systems(
    @app.Update,
    @app.system(toggle_pause).run_if(input_toggle_pressed),
  )
  .add_systems(
    @app.Update,
    @app.system(change_time_speed_up).run_if(input_speed_up_pressed),
  )
  .add_systems(
    @app.Update,
    @app.system(change_time_speed_down).run_if(input_speed_down_pressed),
  )
  .add_systems(
    @app.Update,
    @app.system(update_info_text).run_if(
      @time.on_real_timer(@core.Duration::from_millis(250L)),
    ),
  )
  .run()
}
