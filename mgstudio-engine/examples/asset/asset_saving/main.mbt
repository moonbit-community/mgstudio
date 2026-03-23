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
/// Port of `bevy/examples/asset/asset_saving.rs`.

///|
const ASSET_PATH : String = "my_scene.boxes"

///|
const BOX_HALF_EXTENT : Float = 50.0F

///|
const ROTATE_HUE_SPEED_DEG_PER_SEC : Float = 180.0F

///|
struct OneBox {
  position : @math.Vec2
  color : @sprite.Color
} derive(ToJson, FromJson)

///|
struct ManyBoxes {
  boxes : Array[@asset.Handle[OneBox]]
}

///|
struct SerializableManyBoxes {
  boxes : Array[OneBox]
} derive(ToJson, FromJson)

///|
struct Box {}

///|
struct PendingLoad {
  handle : @asset.Handle[ManyBoxes]
}

///|
struct BoxEditingState {
  mut dragging : @core.Entity?
  mut drag_offset : @math.Vec2
  mut rotating : @core.Entity?
}

///|
let box_key : @ecs.ComponentKey[Box] = @ecs.register_component(
  debug_name="examples.asset.asset_saving.Box",
)

///|
let pending_load_key : @ecs.ComponentKey[PendingLoad] = @ecs.register_component(
  debug_name="examples.asset.asset_saving.PendingLoad",
)

///|
let box_editing_state_key : @ecs.ResourceKey[BoxEditingState] = @ecs.register_resource(
  debug_name="examples.asset.asset_saving.BoxEditingState",
)

///|
pub impl @ecs.Component for Box with component() {
  box_key
}

///|
pub impl @ecs.Component for PendingLoad with component() {
  pending_load_key
}

///|
pub impl @app.Resource for BoxEditingState with resource() {
  box_editing_state_key
}

///|
fn BoxEditingState::default() -> BoxEditingState {
  BoxEditingState::{
    dragging: None,
    drag_offset: @math.Vec2::zero(),
    rotating: None,
  }
}

///|
fn help_text() -> String {
  "LMB (on background) - spawn new box\n" +
  "LMB (on box) - drag to move\n" +
  "RMB (on box) - rotate colors\n" +
  "F5 - Save boxes\n" +
  "F6 - Load boxes"
}

///|
fn color_from_hue_deg(hue_deg : Float) -> @sprite.Color {
  @sprite.Color::hsla(hue_deg, 1.0F, 0.5F, 1.0F)
}

///|
fn wrap_hue_deg(value : Float) -> Float {
  let mut hue = value
  while hue >= 360.0F {
    hue = hue - 360.0F
  }
  while hue < 0.0F {
    hue = hue + 360.0F
  }
  hue
}

///|
fn color_hue_deg(color : @sprite.Color) -> Float {
  let r = color.r
  let g = color.g
  let b = color.b
  let max_channel = if r >= g && r >= b { r } else if g >= b { g } else { b }
  let min_channel = if r <= g && r <= b { r } else if g <= b { g } else { b }
  let delta = max_channel - min_channel
  if delta <= 0.000001F {
    return 0.0F
  }
  let raw_hue = if max_channel == r {
    (g - b) / delta
  } else if max_channel == g {
    (b - r) / delta + 2.0F
  } else {
    (r - g) / delta + 4.0F
  }
  wrap_hue_deg(raw_hue * 60.0F)
}

///|
fn rotate_hue(color : @sprite.Color, delta_deg : Float) -> @sprite.Color {
  color_from_hue_deg(color_hue_deg(color) + delta_deg)
}

///|
fn box_to_json_bytes(boxes : SerializableManyBoxes) -> Bytes {
  @utf8.encode(boxes.to_json().stringify()[:])
}

///|
fn bytes_to_text(bytes : Bytes) -> String {
  @utf8.decode_lossy(bytes[:], ignore_bom=true)
}

///|
fn load_many_boxes(context : @asset.LoadContext, bytes : Bytes) -> ManyBoxes {
  let json = @json.parse(bytes_to_text(bytes)) catch {
    _ => abort("Failed to parse saved ManyBoxes asset")
  }
  let decoded : SerializableManyBoxes = try! @json.from_json(json)
  let boxes : Array[@asset.Handle[OneBox]] = []
  for i in 0..<decoded.boxes.length() {
    boxes.push(context.add_labeled_asset(i.to_string(), decoded.boxes[i]))
  }
  ManyBoxes::{ boxes, }
}

///|
fn many_boxes_saver() -> @asset.AssetSaver[ManyBoxes, Unit] {
  @asset.AssetSaver::new(fn(writer, asset, _settings) {
    let root = asset.get()
    let boxes : Array[OneBox] = []
    for handle in root.boxes {
      let label = match asset.label_for(handle) {
        Some(value) => value
        None =>
          return Err(
            "Missing label for subasset handle " + handle.id().to_string(),
          )
      }
      let saved_one_box : @asset.SavedAsset[OneBox] = match
        asset.get_labeled(label) {
        Some(saved_one_box) => saved_one_box
        None => return Err("Failed to find saved subasset for label " + label)
      }
      boxes.push(saved_one_box.get())
    }
    writer.write_all(box_to_json_bytes(SerializableManyBoxes::{ boxes, }))
    Ok(())
  })
}

///|
fn asset_saving_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @asset.init_asset_loader(
    @asset.init_asset(
      @asset.init_asset(app, fn() {
        OneBox::{ position: @math.Vec2::zero(), color: @sprite.Color::white() }
      }),
      fn() { ManyBoxes::{ boxes: [] } },
    ),
    @asset.AssetLoader::new_with_context(["boxes"], load_many_boxes),
  )
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @text.Text::new(help_text()),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
      ),
    ),
  )
}

///|
fn box_at_cursor(
  boxes : @ecs.Query2Filtered[
    @sprite.Sprite,
    @transform.Transform,
    @ecs.With[Box],
  ],
  cursor_world : @math.Vec2,
) -> @core.Entity? {
  let hit : Ref[@core.Entity?] = Ref::new(None)
  try! boxes.view(fn(entity, _sprite, transform) {
    let center = @math.Vec2::new(
      transform.translation.x,
      transform.translation.y,
    )
    if cursor_world.x >= center.x - BOX_HALF_EXTENT &&
      cursor_world.x <= center.x + BOX_HALF_EXTENT &&
      cursor_world.y >= center.y - BOX_HALF_EXTENT &&
      cursor_world.y <= center.y + BOX_HALF_EXTENT {
      hit.val = Some(entity)
    }
  })
  hit.val
}

///|
fn spawn_box_entity(
  commands : @app.Commands,
  position : @math.Vec2,
  color : @sprite.Color,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(@asset.asset_white_texture())
        .with_color(color)
        .with_custom_size(
          Some(@math.Vec2::new(BOX_HALF_EXTENT * 2.0F, BOX_HALF_EXTENT * 2.0F)),
        ),
        @transform.Transform::from_xyz(position.x, position.y, 0.0F),
        Box::{  },
      ),
    ),
  )
}

///|
fn current_cursor_world() -> @math.Vec2? {
  guard @app.current_world() is Some(world) else { return None }
  guard @input.mouse_position() is Some(cursor_position) else { return None }
  @sprite.render2d_viewport_to_world_2d(world, cursor_position)
}

///|
fn box_editing_input(
  commands : @app.Commands,
  state : @app.ResMut[BoxEditingState],
  boxes : @ecs.Query2Filtered[
    @sprite.Sprite,
    @transform.Transform,
    @ecs.With[Box],
  ],
) -> Unit {
  guard current_cursor_world() is Some(cursor_world) else { return }
  let state_ref = state.get_ref()

  if @input.mouse_button_just_pressed(@window.MouseButton::Left) {
    match box_at_cursor(boxes, cursor_world) {
      Some(entity) => {
        guard (try! boxes.get(entity)) is Some((_sprite, transform)) else {
          return
        }
        state_ref.val.dragging = Some(entity)
        state_ref.val.drag_offset = @math.Vec2::new(
          transform.translation.x - cursor_world.x,
          transform.translation.y - cursor_world.y,
        )
      }
      None =>
        spawn_box_entity(
          commands,
          cursor_world,
          @sprite.Color::srgb(0.94F, 0.27F, 0.27F),
        )
    }
  }

  if @input.mouse_button_just_released(@window.MouseButton::Left) {
    state_ref.val.dragging = None
  }

  if @input.mouse_button_pressed(@window.MouseButton::Left) {
    if state_ref.val.dragging is Some(entity) {
      let next_position = @math.Vec2::new(
        cursor_world.x + state_ref.val.drag_offset.x,
        cursor_world.y + state_ref.val.drag_offset.y,
      )
      try! boxes.view(fn(candidate, _sprite, transform) {
        if candidate == entity {
          transform.translation.x = next_position.x
          transform.translation.y = next_position.y
        }
      })
    }
  }

  if @input.mouse_button_just_pressed(@window.MouseButton::Right) {
    state_ref.val.rotating = box_at_cursor(boxes, cursor_world)
  }

  if @input.mouse_button_just_released(@window.MouseButton::Right) {
    state_ref.val.rotating = None
  } else if state_ref.val.rotating is Some(entity) &&
    box_at_cursor(boxes, cursor_world) is Some(hovered) &&
    (hovered.id != entity.id || hovered.generation != entity.generation) {
    state_ref.val.rotating = None
  } else if state_ref.val.rotating is Some(_) &&
    box_at_cursor(boxes, cursor_world) is None {
    state_ref.val.rotating = None
  }
}

///|
fn rotate_box_hue(
  state : @app.Res[BoxEditingState],
  time : @app.Res[@time.Time[Unit]],
  boxes : @ecs.Query2Filtered[
    @sprite.Sprite,
    @transform.Transform,
    @ecs.With[Box],
  ],
) -> Unit {
  guard state.get().rotating is Some(entity) else { return }
  let delta = time.get().delta_seconds() * ROTATE_HUE_SPEED_DEG_PER_SEC
  try! boxes.view(fn(candidate, sprite, _transform) {
    if candidate == entity {
      sprite.color = rotate_hue(sprite.color, delta)
    }
  })
}

///|
fn perform_save(
  boxes : @ecs.Query2Filtered[
    @sprite.Sprite,
    @transform.Transform,
    @ecs.With[Box],
  ],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let one_boxes : Array[OneBox] = []
  try! boxes.view(fn(_entity, sprite, transform) {
    one_boxes.push(OneBox::{
      position: @math.Vec2::new(
        transform.translation.x,
        transform.translation.y,
      ),
      color: sprite.color,
    })
  })
  let server = asset_server.get()
  @tasks.IoTaskPool::get()
  .spawn(fn() {
    let builder = @asset.SavedAssetBuilder::new(
      server,
      @asset.AssetPath::from_path(ASSET_PATH),
    )
    let many_boxes = ManyBoxes::{ boxes: [] }
    for i in 0..<one_boxes.length() {
      many_boxes.boxes.push(
        builder.add_labeled_asset_with_new_handle(
          i.to_string(),
          @asset.SavedAsset::from_asset(one_boxes[i]),
        ),
      )
    }
    match
      @asset.save_using_saver(
        server,
        many_boxes_saver(),
        @asset.AssetPath::from_path(ASSET_PATH),
        builder.build(many_boxes),
        (),
      ) {
      Ok(_) => @app.log_info("Completed save of " + ASSET_PATH)
      Err(err) => @app.log_error("Failed to save asset: " + err)
    }
  })
  .detach()
}

///|
fn start_load(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn_component(PendingLoad::{
      handle: asset_server.get().load(ASSET_PATH),
    }),
  )
}

///|
fn wait_for_pending_loads(
  loads : @ecs.Query1Filtered[PendingLoad, @ecs.With[PendingLoad]],
  many_boxes_assets : @app.Res[@asset.Assets[ManyBoxes]],
  one_boxes_assets : @app.Res[@asset.Assets[OneBox]],
  existing_boxes : @ecs.Query1Filtered[Box, @ecs.With[Box]],
  commands : @app.Commands,
) -> Unit {
  let ready_loads : Array[(@core.Entity, ManyBoxes)] = []
  try! loads.view(fn(entity, load) {
    if many_boxes_assets.get().get(load.handle) is Some(many_boxes) {
      ready_loads.push((entity, many_boxes))
    }
  })
  if ready_loads.length() == 0 {
    return
  }

  for entry in ready_loads {
    let (entity, _many_boxes) = entry
    commands.entity(entity).despawn()
  }

  try! existing_boxes.view(fn(entity, _box) {
    commands.entity(entity).despawn()
  })

  for entry in ready_loads {
    let (_entity, many_boxes) = entry
    for handle in many_boxes.boxes {
      guard one_boxes_assets.get().get(handle) is Some(one_box) else {
        continue
      }
      spawn_box_entity(commands, one_box.position, one_box.color)
    }
  }
}

///|
fn main {
  asset_saving_plugin(
    @app.App::new(@ecs.World::new()).add_plugin_group(fn() {
      @mgstudio.DefaultPlugins::set(
        @asset.AssetPlugin::default().with_file_path(
          "examples/asset/saved_assets",
        ),
      )
    }),
  )
  .insert_resource(BoxEditingState::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(box_editing_input)))
  .add_systems(@app.Update, @app.system(@app.system_param3(rotate_box_hue)))
  .add_systems(
    @app.PreUpdate,
    @app.system(@app.system_param2(perform_save)).run_if(
      @input.input_just_pressed(@window.KeyCode::F5),
    ),
  )
  .add_systems(
    @app.PreUpdate,
    @app.system(@app.system_param2(start_load)).run_if(
      @input.input_just_pressed(@window.KeyCode::F6),
    ),
  )
  .add_systems(
    @app.PreUpdate,
    @app.system(@app.system_param5(wait_for_pending_loads)),
  )
  .run()
}
