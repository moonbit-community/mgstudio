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
/// Port of `bevy/examples/input/gamepad_input_events.rs`.
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(gamepad_setup)
  .add_system(gamepad_events_system)
  .add_system(gamepad_visual_system)
  .run()
}

///|
priv struct ExampleState {
  mut instruction_font : @asset.Handle[@asset.Font]?
  mut instruction_spawned : Bool
}

///|
let example_state : Ref[ExampleState] = Ref::new(ExampleState::{
  instruction_font: None,
  instruction_spawned: false,
})

///|
fn gamepad_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()

  let texture = asset_server.load("branding/icon.png")
  let sprite = @render2d.Sprite::from_image(texture)
  @render2d.SpriteBundle::new(
    sprite,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -70.0F),
      0.0F,
      @math.Vec2::new(0.55F, 0.55F),
    ),
  ).spawn(world)
  |> ignore

  example_state.val.instruction_font = Some(
    asset_server.load_font("fonts/FiraSans-Bold.ttf"),
  )
  example_state.val.instruction_spawned = false

  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[gamepad_input_events] " + text)
}

///|
fn maybe_int_text(value : Int?) -> String {
  if value is Some(v) {
    v.to_string()
  } else {
    "unknown"
  }
}

///|
fn ensure_instruction_text() -> Unit {
  if example_state.val.instruction_spawned {
    return
  }
  guard example_state.val.instruction_font is Some(font) else { return }
  guard @asset.asset_font_read_bytes(font) is Some(_) else { return }

  let instructions = @text.Text2d::new(
    (
      #|Gamepad Input Events Demo
      #|How to use:
      #|1) Connect a gamepad (click page first on web).
      #|2) Move LEFT STICK to move the icon.
      #|3) Hold RIGHT TRIGGER to rotate the icon.
      #|4) Press SOUTH to see press/release events in logs.
      #|5) Connection/button/axis events are also logged.
      #|,
    ),
  )
  let instruction_style = @text.TextFont::default()
    .with_font(font)
    .with_font_size(16.0F)
  @text.Text2dBundle::new(
    instructions,
    instruction_style,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 170.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  .with_bounds(@text.TextBounds::new_horizontal(700.0F))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .with_color(@text.TextColor::new(@render2d.Color::white()))
  .spawn()
  |> ignore

  example_state.val.instruction_spawned = true
}

///|
fn gamepad_events_system(_world : @ecs_world.World) -> Unit {
  for event in @input.gamepad_events() {
    match event {
      Connection(connection) => {
        let id = connection.gamepad_id
        match connection.connection {
          Connected(info) =>
            log_line(
              "connected id=\{id} name=\{info.name} vendor=\{maybe_int_text(info.vendor_id)} product=\{maybe_int_text(info.product_id)}",
            )
          Disconnected => log_line("disconnected id=\{id}")
        }
      }
      Button(button) =>
        log_line(
          "button id=\{button.gamepad_id} button_index=\{button.button.to_index()} value=\{button.value}",
        )
      Axis(axis) =>
        log_line(
          "axis id=\{axis.gamepad_id} axis_index=\{axis.axis.to_index()} value=\{axis.value}",
        )
    }
  }

  for gamepad in @input.gamepads() {
    if gamepad.just_pressed(@input.GamepadButton::South) {
      log_line("\{gamepad.id()} just pressed South")
    } else if gamepad.just_released(@input.GamepadButton::South) {
      log_line("\{gamepad.id()} just released South")
    }
  }
}

///|
fn gamepad_visual_system(world : @ecs_world.World) -> Unit {
  ensure_instruction_text()

  let mut move_axis = @math.Vec2::new(0.0F, 0.0F)
  let mut rotate_speed = 0.0F

  if @input.gamepads().length() > 0 {
    let gamepad = @input.gamepads()[0]
    move_axis = gamepad.left_stick()
    rotate_speed = gamepad
      .get(@input.GamepadInput::Button(@input.GamepadButton::RightTrigger2))
      .unwrap_or(0.0F)
  }

  let delta = @time.time_delta_seconds()
  let tick = world.read_change_tick()
  let transform_store = world.get_transform_store()
  let sprite_store = world.get_sprite_store()
  let entities : Array[(@core.Entity, @math.Transform)] = []
  @core.query2(transform_store, sprite_store, fn(entity, transform, _sprite) {
    entities.push((entity, transform))
  })

  let speed = 260.0F
  for entry in entities {
    let transform = entry.1
    let tx = transform.translation.x + move_axis.x * speed * delta
    let ty = transform.translation.y + move_axis.y * speed * delta
    let next_transform = @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(tx, ty),
      transform.rotation_z() + rotate_speed * delta * 3.0F,
      @math.Vec2::new(transform.scale.x, transform.scale.y),
      z=transform.translation.z,
    )
    transform_store.set(entry.0, next_transform, tick) |> ignore
  }
}
