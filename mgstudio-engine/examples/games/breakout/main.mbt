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
const PADDLE_SIZE_X : Float = 120.0F

///|
const PADDLE_SIZE_Y : Float = 20.0F

///|
const GAP_BETWEEN_PADDLE_AND_FLOOR : Float = 60.0F

///|
const PADDLE_SPEED : Float = 500.0F

///|
const PADDLE_PADDING : Float = 10.0F

///|
const BALL_STARTING_POSITION_X : Float = 0.0F

///|
const BALL_STARTING_POSITION_Y : Float = -50.0F

///|
const BALL_STARTING_POSITION_Z : Float = 1.0F

///|
const BALL_DIAMETER : Float = 30.0F

///|
const BALL_SPEED : Float = 400.0F

///|
const INITIAL_BALL_DIRECTION_X : Float = 0.5F

///|
const INITIAL_BALL_DIRECTION_Y : Float = -0.5F

///|
const WALL_THICKNESS : Float = 10.0F

///|
const LEFT_WALL : Float = -450.0F

///|
const RIGHT_WALL : Float = 450.0F

///|
const BOTTOM_WALL : Float = -300.0F

///|
const TOP_WALL : Float = 300.0F

///|
const BRICK_SIZE_X : Float = 100.0F

///|
const BRICK_SIZE_Y : Float = 30.0F

///|
const GAP_BETWEEN_PADDLE_AND_BRICKS : Float = 270.0F

///|
const GAP_BETWEEN_BRICKS : Float = 5.0F

///|
const GAP_BETWEEN_BRICKS_AND_CEILING : Float = 20.0F

///|
const GAP_BETWEEN_BRICKS_AND_SIDES : Float = 20.0F

///|
const SCOREBOARD_FONT_SIZE : Float = 33.0F

///|
const SCOREBOARD_TEXT_PADDING : Float = 5.0F

///|
let background_color : @color.Color = @color.Color::srgb(0.9F, 0.9F, 0.9F)

///|
let paddle_color : @color.Color = @color.Color::srgb(0.3F, 0.3F, 0.7F)

///|
let ball_color : @color.Color = @color.Color::srgb(1.0F, 0.5F, 0.5F)

///|
let brick_color : @color.Color = @color.Color::srgb(0.5F, 0.5F, 1.0F)

///|
let wall_color : @color.Color = @color.Color::srgb(0.8F, 0.8F, 0.8F)

///|
let text_color : @color.Color = @color.Color::srgb(0.5F, 0.5F, 1.0F)

///|
let score_color : @color.Color = @color.Color::srgb(1.0F, 0.5F, 0.5F)

///|
struct Paddle {}

///|
struct Ball {}

///|
struct Velocity {
  value : @math.Vec2
}

///|
struct BallCollided {}

///|
struct Brick {}

///|
struct Collider {}

///|
struct Wall {}

///|
enum WallLocation {
  Left
  Right
  Bottom
  Top
}

///|
struct Score {
  mut value : Int
}

///|
struct CollisionSound {
  sound : @asset.Handle[@audio.AudioSource]
}

///|
struct ScoreboardUi {}

///|
enum Collision {
  Left
  Right
  Top
  Bottom
} derive(Eq, Debug)

///|
let paddle_key : @ecs.ComponentKey[Paddle] = @ecs.register_component(
  debug_name="examples.games.breakout.Paddle",
)

///|
let ball_key : @ecs.ComponentKey[Ball] = @ecs.register_component(
  debug_name="examples.games.breakout.Ball",
)

///|
let velocity_key : @ecs.ComponentKey[Velocity] = @ecs.register_component(
  debug_name="examples.games.breakout.Velocity",
)

///|
let brick_key : @ecs.ComponentKey[Brick] = @ecs.register_component(
  debug_name="examples.games.breakout.Brick",
)

///|
let collider_key : @ecs.ComponentKey[Collider] = @ecs.register_component(
  debug_name="examples.games.breakout.Collider",
)

///|
let wall_key : @ecs.ComponentKey[Wall] = @ecs.register_component(
  debug_name="examples.games.breakout.Wall",
)

///|
let scoreboard_ui_key : @ecs.ComponentKey[ScoreboardUi] = @ecs.register_component(
  debug_name="examples.games.breakout.ScoreboardUi",
)

///|
let score_key : @ecs.ResourceKey[Score] = @ecs.register_resource(
  debug_name="examples.games.breakout.Score",
)

///|
let collision_sound_key : @ecs.ResourceKey[CollisionSound] = @ecs.register_resource(
  debug_name="examples.games.breakout.CollisionSound",
)

///|
let ball_collided_event_key : @ecs.EventKey[BallCollided] = @ecs.register_event(
  debug_name="examples.games.breakout.BallCollided",
)

///|
pub impl @ecs.Component for Paddle with fn component() {
  paddle_key
}

///|
pub impl @ecs.Component for Ball with fn component() {
  ball_key
}

///|
pub impl @ecs.Component for Velocity with fn component() {
  velocity_key
}

///|
pub impl @ecs.Component for Brick with fn component() {
  brick_key
}

///|
pub impl @ecs.Component for Collider with fn component() {
  collider_key
}

///|
pub impl @ecs.Component for Wall with fn component() {
  wall_key
}

///|
pub impl @ecs.Component for ScoreboardUi with fn component() {
  scoreboard_ui_key
}

///|
impl @app.Resource for Score with fn resource() {
  score_key
}

///|
impl @app.Resource for CollisionSound with fn resource() {
  collision_sound_key
}

///|
pub impl @ecs.TriggerEvent for BallCollided with fn observer_event() {
  ball_collided_event_key
}

///|
pub impl @ecs.TriggerEvent for BallCollided with fn observer_entity(_self) {
  None
}

///|
pub impl @ecs.TriggerEvent for BallCollided with fn set_observer_entity(
  self,
  _entity,
) {
  self
}

///|
pub impl @ecs.TriggerEvent for BallCollided with fn auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for BallCollided with fn debug_name() {
  "BallCollided"
}

///|
fn ball_starting_position() -> @math.Vec3 {
  @math.Vec3::new(
    BALL_STARTING_POSITION_X,
    BALL_STARTING_POSITION_Y,
    BALL_STARTING_POSITION_Z,
  )
}

///|
fn initial_ball_velocity() -> Velocity {
  let direction = @math.Vec2::new(
    INITIAL_BALL_DIRECTION_X,
    INITIAL_BALL_DIRECTION_Y,
  ).normalize()
  Velocity::{ value: direction.mul_scalar(BALL_SPEED) }
}

///|
fn wall_location_position(location : WallLocation) -> @math.Vec2 {
  match location {
    Left => @math.Vec2::new(LEFT_WALL, 0.0F)
    Right => @math.Vec2::new(RIGHT_WALL, 0.0F)
    Bottom => @math.Vec2::new(0.0F, BOTTOM_WALL)
    Top => @math.Vec2::new(0.0F, TOP_WALL)
  }
}

///|
fn wall_location_size(location : WallLocation) -> @math.Vec2 {
  let arena_height = TOP_WALL - BOTTOM_WALL
  let arena_width = RIGHT_WALL - LEFT_WALL
  match location {
    Left | Right =>
      @math.Vec2::new(WALL_THICKNESS, arena_height + WALL_THICKNESS)
    Bottom | Top =>
      @math.Vec2::new(arena_width + WALL_THICKNESS, WALL_THICKNESS)
  }
}

///|
fn wall_bundle(
  location : WallLocation,
) -> (Wall, @sprite.Sprite, @transform.Transform, Collider) {
  let position = wall_location_position(location)
  let size = wall_location_size(location)
  (
    Wall::{  },
    @sprite.Sprite::from_color(wall_color, @math.Vec2::new(1.0F, 1.0F)),
    @transform.Transform::from_xyz(position.x, position.y, 0.0F).with_scale(
      @math.Vec3::new(size.x, size.y, 1.0F),
    ),
    Collider::{  },
  )
}

///|
fn vec3_xy(value : @math.Vec3) -> @math.Vec2 {
  @math.Vec2::new(value.x, value.y)
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn clampf(value : Float, lower : Float, upper : Float) -> Float {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[
    @asset.Assets[@sprite_render_mesh2d_color_material.ColorMaterial],
  ],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))

  commands.insert_resource(CollisionSound::{
    sound: asset_server.get().load("sounds/breakout_collision.ogg"),
  })

  let paddle_y = BOTTOM_WALL + GAP_BETWEEN_PADDLE_AND_FLOOR
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_color(paddle_color, @math.Vec2::new(1.0F, 1.0F)),
        @transform.Transform::from_xyz(0.0F, paddle_y, 0.0F).with_scale(
          @math.Vec3::new(PADDLE_SIZE_X, PADDLE_SIZE_Y, 1.0F),
        ),
        Paddle::{  },
        Collider::{  },
      ),
    ),
  )

  let ball_mesh = meshes.modify(fn(mesh_assets) {
    @mesh_primitives.add_mesh(mesh_assets, @math.Circle::new(0.5F))
  })
  let ball_material = materials.modify(fn(material_assets) {
    material_assets.add(
      @sprite_render_mesh2d_color_material.ColorMaterial::from_color(ball_color),
    )
  })
  ignore(
    commands.spawn(
      (
        @mesh.Mesh2d::new(ball_mesh),
        @sprite_render_mesh2d_material.MeshMaterial2d::new(ball_material),
        @transform.Transform::from_translation(ball_starting_position()).with_scale(
          @math.Vec3::new(BALL_DIAMETER, BALL_DIAMETER, 1.0F),
        ),
        Ball::{  },
        initial_ball_velocity(),
      ),
    ),
  )

  let scoreboard = commands.spawn(
    (
      @text.Text::new("Score: "),
      @text.TextFont::TextFont().with_font_size(SCOREBOARD_FONT_SIZE),
      @text.TextColor::new(text_color),
      ScoreboardUi::{  },
      @ui.Node::Node()
      .with_position_type(@ui.PositionType::Absolute)
      .with_top(@ui.Val::Px(SCOREBOARD_TEXT_PADDING))
      .with_left(@ui.Val::Px(SCOREBOARD_TEXT_PADDING)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(scoreboard),
        @text.TextSpan::TextSpan(),
        @text.TextFont::TextFont().with_font_size(SCOREBOARD_FONT_SIZE),
        @text.TextColor::new(score_color),
      ),
    ),
  )

  ignore(commands.spawn(wall_bundle(Left)))
  ignore(commands.spawn(wall_bundle(Right)))
  ignore(commands.spawn(wall_bundle(Bottom)))
  ignore(commands.spawn(wall_bundle(Top)))

  let total_width_of_bricks = RIGHT_WALL -
    LEFT_WALL -
    2.0F * GAP_BETWEEN_BRICKS_AND_SIDES
  let bottom_edge_of_bricks = paddle_y + GAP_BETWEEN_PADDLE_AND_BRICKS
  let total_height_of_bricks = TOP_WALL -
    bottom_edge_of_bricks -
    GAP_BETWEEN_BRICKS_AND_CEILING
  let n_columns = (total_width_of_bricks / (BRICK_SIZE_X + GAP_BETWEEN_BRICKS))
    .floor()
    .to_int()
  let n_rows = (total_height_of_bricks / (BRICK_SIZE_Y + GAP_BETWEEN_BRICKS))
    .floor()
    .to_int()
  let n_vertical_gaps = n_columns - 1
  let center_of_bricks = (LEFT_WALL + RIGHT_WALL) / 2.0F
  let left_edge_of_bricks = center_of_bricks -
    float_from_int(n_columns) / 2.0F * BRICK_SIZE_X -
    float_from_int(n_vertical_gaps) / 2.0F * GAP_BETWEEN_BRICKS
  let offset_x = left_edge_of_bricks + BRICK_SIZE_X / 2.0F
  let offset_y = bottom_edge_of_bricks + BRICK_SIZE_Y / 2.0F
  for row in 0..<n_rows {
    for column in 0..<n_columns {
      let brick_position = @math.Vec2::new(
        offset_x + float_from_int(column) * (BRICK_SIZE_X + GAP_BETWEEN_BRICKS),
        offset_y + float_from_int(row) * (BRICK_SIZE_Y + GAP_BETWEEN_BRICKS),
      )
      ignore(
        commands.spawn(
          (
            @sprite.Sprite::from_color(brick_color, @math.Vec2::new(1.0F, 1.0F)),
            @transform.Transform::from_xyz(
              brick_position.x,
              brick_position.y,
              0.0F,
            ).with_scale(@math.Vec3::new(BRICK_SIZE_X, BRICK_SIZE_Y, 1.0F)),
            Brick::{  },
            Collider::{  },
          ),
        ),
      )
    }
  }
}

///|
fn move_paddle(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  paddle_transform : @app.Single[
    @ecs.Write[@transform.Transform],
    @ecs.With[Paddle],
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let mut direction = 0.0F
  if keyboard_input.pressed(ArrowLeft) {
    direction = direction - 1.0F
  }
  if keyboard_input.pressed(ArrowRight) {
    direction = direction + 1.0F
  }
  let paddle_transform = paddle_transform.get()
  let new_paddle_position = paddle_transform.value().translation.x +
    direction * PADDLE_SPEED * time.get().delta_secs()
  let left_bound = LEFT_WALL +
    WALL_THICKNESS / 2.0F +
    PADDLE_SIZE_X / 2.0F +
    PADDLE_PADDING
  let right_bound = RIGHT_WALL -
    WALL_THICKNESS / 2.0F -
    PADDLE_SIZE_X / 2.0F -
    PADDLE_PADDING
  paddle_transform.modify(fn(transform) {
    transform.translation.x = clampf(
      new_paddle_position, left_bound, right_bound,
    )
  })
}

///|
fn apply_velocity(
  query : @ecs.Query[
    (@ecs.Write[@transform.Transform], @ecs.Read[Velocity]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta_secs = time.get().delta_secs()
  try! query.view(fn(_entity, data) {
    let (transform, velocity) = data
    transform.modify(fn(value) {
      value.translation.x += velocity.value().value.x * delta_secs
      value.translation.y += velocity.value().value.y * delta_secs
    })
  })
}

///|
fn update_scoreboard(
  score : @app.Res[Score],
  score_root : @app.Single[
    @core.Entity,
    (@ecs.With[ScoreboardUi], @ecs.With[@text.Text]),
  ],
  writer : @ui.TextUiWriter,
) -> Unit {
  ignore(writer.set_text(score_root.get(), 1, score.get().value.to_string()))
}

///|
fn check_for_collisions(
  commands : @app.Commands,
  score : @app.ResMut[Score],
  ball_query : @app.Single[
    (@ecs.Write[Velocity], @ecs.Read[@transform.Transform]),
    @ecs.With[Ball],
  ],
  collider_query : @ecs.Query[
    (@core.Entity, @ecs.Read[@transform.Transform], @ecs.Has[Brick]),
    @ecs.With[Collider],
  ],
) -> Unit {
  let (ball_velocity, ball_transform) = ball_query.get()
  try! collider_query.view(fn(_query_entity, data) {
    let (collider_entity, collider_transform, is_brick) = data
    let collision = ball_collision(
      @math.BoundingCircle::new(
        vec3_xy(ball_transform.value().translation),
        BALL_DIAMETER / 2.0F,
      ),
      @math.Aabb2d::new(
        vec3_xy(collider_transform.value().translation),
        vec3_xy(collider_transform.value().scale).mul_scalar(0.5F),
      ),
    )
    guard collision is Some(collision) else { return }

    commands.trigger(BallCollided::{  })
    if is_brick.present() {
      commands.entity(collider_entity).despawn()
      ignore(
        score.modify(fn(value) {
          value.value = value.value + 1
          value.value
        }),
      )
    }

    let mut reflect_x = false
    let mut reflect_y = false
    match collision {
      Left => reflect_x = ball_velocity.value().value.x > 0.0F
      Right => reflect_x = ball_velocity.value().value.x < 0.0F
      Top => reflect_y = ball_velocity.value().value.y < 0.0F
      Bottom => reflect_y = ball_velocity.value().value.y > 0.0F
    }
    ball_velocity.modify(fn(velocity) {
      if reflect_x {
        velocity.value.x = -velocity.value.x
      }
      if reflect_y {
        velocity.value.y = -velocity.value.y
      }
    })
  })
}

///|
fn play_collision_sound(
  _collided : @ecs.On[BallCollided],
  commands : @app.Commands,
  sound : @app.Res[CollisionSound],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @audio.AudioPlayer::new(sound.get().sound),
        @audio.PlaybackSettings::despawn(),
      ),
    ),
  )
}

///|
fn ball_collision(
  ball : @math.BoundingCircle,
  bounding_box : @math.Aabb2d,
) -> Collision? {
  if !ball.intersects_aabb(bounding_box) {
    return None
  }
  let closest = bounding_box.closest_point(ball.center)
  let offset = ball.center.sub(closest)
  if @math.abs(offset.x) > @math.abs(offset.y) {
    if offset.x < 0.0F {
      Some(Left)
    } else {
      Some(Right)
    }
  } else if offset.y > 0.0F {
    Some(Top)
  } else {
    Some(Bottom)
  }
}

///|
fn main {
  let apply_velocity_system : @app.SystemConfig[@ecs.World] = @app.system_config_param2(
    apply_velocity,
  )
  let move_paddle_system : @app.SystemConfig[@ecs.World] = @app.system_config_param3(
    move_paddle,
  )
  let check_for_collisions_system : @app.SystemConfig[@ecs.World] = @app.system_config_param4(
    check_for_collisions,
  )
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .insert_resource(Score::{ value: 0 })
  .insert_resource(@camera_clear_color.ClearColor::new(background_color))
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param4(@app.Startup, setup)
  .add_systems(
    @app.Update,
    (apply_velocity_system, move_paddle_system, check_for_collisions_system)
    |> @app.chain(),
  )
  .add_systems_param3(@app.Update, update_scoreboard)
  .add_observer3(play_collision_sound)
  .run()
}
