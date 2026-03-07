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
  mut real_sprite : @core.Entity?
  mut virtual_sprite : @core.Entity?
  mut real_text : @text.TextHandle?
  mut virtual_text : @text.TextHandle?
  mut info_timer : @time.Timer
}

///|
let virtual_time_state : Ref[VirtualTimeState] = Ref::new({
  real_sprite: None,
  virtual_sprite: None,
  real_text: None,
  virtual_text: None,
  info_timer: @time.Timer::from_seconds(0.25F, @time.TimerMode::Repeating),
})

///|
fn read_real_time(world : @ecs.World) -> @time.Time[@time.Real] {
  let real_time = try! world.get_resource(@time.real_time_resource_key())
  match real_time {
    Some(real_time) => real_time
    None => {
      let time : @time.Time[@time.Real] = @time.Time::default()
      time
    }
  }
}

///|
fn read_virtual_time(world : @ecs.World) -> @time.Time[@time.Virtual] {
  let virtual_time = try! world.get_resource(@time.virtual_time_resource_key())
  match virtual_time {
    Some(virtual_time) => virtual_time
    None => {
      let time : @time.Time[@time.Virtual] = @time.Time::default()
      time
    }
  }
}

///|
fn read_generic_time(world : @ecs.World) -> @time.Time[Unit] {
  let time = try! world.get_resource(@time.default_time_resource_key())
  match time {
    Some(time) => time
    None => {
      let default_time : @time.Time[Unit] = @time.Time::default()
      default_time
    }
  }
}

///|
fn update_virtual_time_resource(
  world : @ecs.World,
  update : (@time.Time[@time.Virtual]) -> @time.Time[@time.Virtual],
) -> Unit {
  let change_tick = world.increment_change_tick()
  let virtual_ref = try! world
    .get_resource_ref_mut(@time.virtual_time_resource_key(), change_tick)
    .unwrap()
  let time_ref = try! world
    .get_resource_ref_mut(@time.default_time_resource_key(), change_tick)
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
  virtual_time_state.val = {
    real_sprite: None,
    virtual_sprite: None,
    real_text: None,
    virtual_text: None,
    info_timer: @time.Timer::from_seconds(0.25F, @time.TimerMode::Repeating),
  }

  update_virtual_time_resource(world, fn(
    virtual_time : @time.Time[@time.Virtual],
  ) {
    virtual_time.set_relative_speed(2.0F).unpause()
  })

  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let real_sprite = @render2d.SpriteBundle::new(
    @render2d.Sprite::from_image(texture).with_custom_size(
      Some(@math.Vec2::new(256.0F, 256.0F)),
    ),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(0.5F, 0.5F),
    ),
  ).spawn(world)
  virtual_time_state.val.real_sprite = Some(real_sprite)

  let virtual_sprite = @render2d.SpriteBundle::new(
    @render2d.Sprite::from_image(texture)
    .with_color(@render2d.Color::new(1.0F, 0.843F, 0.0F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(256.0F, 256.0F))),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -160.0F),
      0.0F,
      @math.Vec2::new(0.5F, 0.5F),
    ),
  ).spawn(world)
  virtual_time_state.val.virtual_sprite = Some(virtual_sprite)

  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let real_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(24.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(260.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(@text.TextColor::new(@render2d.Color::white()))
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  virtual_time_state.val.real_text = Some(real_text)

  @text.Text2dBundle::new(
    @text.Text2d::new("CONTROLS\n(Un)pause: Space\nSpeed+: Up\nSpeed-: Down"),
    @text.TextFont::default().with_font(font).with_font_size(24.0F),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 320.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=50.0F,
    ),
  )
  .with_anchor(@render2d.Anchor::top_center())
  .with_bounds(@text.TextBounds::new_horizontal(300.0F))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .with_color(
    @text.TextColor::new(@render2d.Color::new(0.85F, 0.85F, 0.85F, 1.0F)),
  )
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore

  let virtual_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(24.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::top_right())
    .with_bounds(@text.TextBounds::new_horizontal(260.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Right))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(1.0F, 0.843F, 0.0F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  virtual_time_state.val.virtual_text = Some(virtual_text)

  update_info_text(world)
}

///|
fn handle_time_controls(world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Space) {
    update_virtual_time_resource(world, fn(
      virtual_time : @time.Time[@time.Virtual],
    ) {
      virtual_time.toggle()
    })
  }
  if @input.key_just_pressed(@window.KeyCode::ArrowUp) {
    let virtual_time = read_virtual_time(world)
    let next_speed = clampf(virtual_time.relative_speed() + 1.0F, 0.25F, 5.0F)
    update_virtual_time_resource(world, fn(
      virtual_time : @time.Time[@time.Virtual],
    ) {
      virtual_time.set_relative_speed(next_speed)
    })
  }
  if @input.key_just_pressed(@window.KeyCode::ArrowDown) {
    let virtual_time = read_virtual_time(world)
    let next_speed = clampf(virtual_time.relative_speed() - 1.0F, 0.25F, 5.0F)
    update_virtual_time_resource(world, fn(
      virtual_time : @time.Time[@time.Virtual],
    ) {
      virtual_time.set_relative_speed(next_speed)
    })
  }
}

///|
fn update_sprite_positions(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let transform_store = world.component(@math.ecs_key_transform)
  let real_time = read_real_time(world)
  let time = read_generic_time(world)

  if virtual_time_state.val.real_sprite is Some(real_sprite) {
    if transform_store.get(real_sprite) is Some(transform) {
      transform_store.set(
        real_sprite,
        transform.with_translation(
          @math.Vec3::new(
            get_sprite_translation_x(real_time.elapsed_seconds()),
            transform.translation.y,
            transform.translation.z,
          ),
        ),
        tick,
      )
      |> ignore
    }
  }

  if virtual_time_state.val.virtual_sprite is Some(virtual_sprite) {
    if transform_store.get(virtual_sprite) is Some(transform) {
      transform_store.set(
        virtual_sprite,
        transform.with_translation(
          @math.Vec3::new(
            get_sprite_translation_x(time.elapsed_seconds()),
            transform.translation.y,
            transform.translation.z,
          ),
        ),
        tick,
      )
      |> ignore
    }
  }
}

///|
fn update_text_with_real_timer(world : @ecs.World) -> Unit {
  let real_time = read_real_time(world)
  virtual_time_state.val.info_timer = virtual_time_state.val.info_timer.tick(
    real_time.delta(),
  )
  if virtual_time_state.val.info_timer.just_finished() {
    update_info_text(world)
  }
}

///|
fn update(world : @ecs.World) -> Unit {
  handle_time_controls(world)
  update_sprite_positions(world)
  update_text_with_real_timer(world)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(update))
  .run()
}
