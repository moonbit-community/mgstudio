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
const SPATIAL_CELL_SIZE : Float = 64.0F

///|
struct Mine {
  pos : @math.Vec2
  size : Float
}

///|
let mine_component_key : @ecs.ComponentKey[Mine] = @ecs.register_component(
  debug_name="examples.ecs.observers.Mine",
)

///|
pub impl @ecs.Component for Mine with component() {
  mine_component_key
}

///|
struct MineWorldState {
  mut explosions_enabled : Bool
  map : @hashmap.HashMap[(Int, Int), Array[@core.Entity]]
}

///|
let mine_world_state_key : @ecs.ResourceKey[MineWorldState] = @ecs.register_resource(
  debug_name="examples.ecs.observers.MineWorldState",
)

///|
pub impl @app.Resource for MineWorldState with resource() {
  mine_world_state_key
}

///|
pub impl Default for MineWorldState with default() {
  { explosions_enabled: true, map: @hashmap.HashMap::new() }
}

///|
struct ExplodeMines {
  pos : @math.Vec2
  radius : Float
}

///|
let explode_mines_event_key : @ecs.EventKey[ExplodeMines] = @ecs.register_event(
  debug_name="examples.ecs.observers.ExplodeMines",
)

///|
pub impl @ecs.TriggerEvent for ExplodeMines with observer_event() {
  explode_mines_event_key
}

///|
pub impl @ecs.TriggerEvent for ExplodeMines with observer_entity(_self) {
  None
}

///|
pub impl @ecs.TriggerEvent for ExplodeMines with set_observer_entity(
  _event_ref,
  _entity,
) {

}

///|
pub impl @ecs.TriggerEvent for ExplodeMines with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for ExplodeMines with debug_name() {
  "ExplodeMines"
}

///|
struct Explode {
  mut entity : @core.Entity
}

///|
let explode_event_key : @ecs.EventKey[Explode] = @ecs.register_event(
  debug_name="examples.ecs.observers.Explode",
)

///|
pub impl @ecs.TriggerEvent for Explode with observer_event() {
  explode_event_key
}

///|
pub impl @ecs.TriggerEvent for Explode with observer_entity(self) {
  Some(self.entity)
}

///|
pub impl @ecs.TriggerEvent for Explode with set_observer_entity(
  event_ref,
  entity,
) {
  event_ref.val.entity = entity
}

///|
pub impl @ecs.TriggerEvent for Explode with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for Explode with debug_name() {
  "Explode"
}

///|
fn cell_for_position(pos : @math.Vec2) -> (Int, Int) {
  (
    (pos.x / SPATIAL_CELL_SIZE).floor().to_int(),
    (pos.y / SPATIAL_CELL_SIZE).floor().to_int(),
  )
}

///|
fn MineWorldState::insert(
  self : MineWorldState,
  entity : @core.Entity,
  mine : Mine,
) -> Unit {
  let tile = cell_for_position(mine.pos)
  let entities = self.map.get_or_init(tile, fn() { [] })
  entities.push(entity)
}

///|
fn MineWorldState::remove_entity(
  self : MineWorldState,
  entity : @core.Entity,
) -> Unit {
  let kept_by_tile : Array[((Int, Int), Array[@core.Entity])] = []
  for entry in self.map {
    let tile = entry.0
    let entities = entry.1
    let kept : Array[@core.Entity] = []
    for current in entities {
      if current != entity {
        kept.push(current)
      }
    }
    if kept.length() > 0 {
      kept_by_tile.push((tile, kept))
    }
  }
  self.map.clear()
  for entry in kept_by_tile {
    self.map.set(entry.0, entry.1)
  }
}

///|
fn MineWorldState::get_nearby(
  self : MineWorldState,
  pos : @math.Vec2,
) -> Array[@core.Entity] {
  let tile = cell_for_position(pos)
  let nearby : Array[@core.Entity] = []
  for dx in -1..<=1 {
    for dy in -1..<=1 {
      let current = (tile.0 + dx, tile.1 + dy)
      if self.map.get(current) is Some(entities) {
        for entity in entities {
          nearby.push(entity)
        }
      }
    }
  }
  nearby
}

///|
fn mine_color(size : Float) -> @sprite.Color {
  let normalized = (size - 12.0F) / 16.0F
  @sprite.Color::hsl(normalized * 320.0F, 0.85F, 0.65F)
}

///|
fn pointer_world_position(
  pointer : @app.OnPointer[@app.PointerDown],
  windows : @ecs.Query[@ecs.Comp[@window.Window], @ecs.All],
) -> @math.Vec2? raise {
  guard windows.single() is Some(window_comp) else { return None }
  let window = window_comp.value()
  let position = pointer.position()
  Some(
    @math.Vec2::new(
      position.x - window.width() / 2.0F,
      window.height() / 2.0F - position.y,
    ),
  )
}

///|
fn spawn_mine(
  commands : @app.Commands,
  pos : @math.Vec2,
  size : Float,
) -> @core.Entity {
  let entity = commands.spawn_component(Mine::{ pos, size })
  ignore(commands.entity(entity).observe3(explode_mine))
  entity
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )
  ignore(spawn_mine(commands, @math.Vec2::new(-260.0F, 120.0F), 16.0F))
  ignore(spawn_mine(commands, @math.Vec2::new(-180.0F, 40.0F), 14.0F))
  ignore(spawn_mine(commands, @math.Vec2::new(-110.0F, -40.0F), 18.0F))
  ignore(spawn_mine(commands, @math.Vec2::new(-20.0F, 90.0F), 20.0F))
  ignore(spawn_mine(commands, @math.Vec2::new(40.0F, -30.0F), 15.0F))
  ignore(spawn_mine(commands, @math.Vec2::new(110.0F, 65.0F), 17.0F))
  ignore(spawn_mine(commands, @math.Vec2::new(190.0F, -80.0F), 22.0F))
  ignore(spawn_mine(commands, @math.Vec2::new(260.0F, 20.0F), 19.0F))
}

///|
fn on_add_mine(
  event : @ecs.ComponentOn[@ecs.Insert, Mine],
  state : @app.ResMut[MineWorldState],
  mines : @ecs.Query[@ecs.Comp[Mine], @ecs.All],
) -> Unit {
  let mine_comp = mines.get(event.entity) catch { _ => None }
  guard mine_comp is Some(mine_comp) else { return }
  state.get_ref().val.insert(event.entity, mine_comp.value())
}

///|
fn on_remove_mine(
  event : @ecs.ComponentOn[@ecs.Remove, Mine],
  state : @app.ResMut[MineWorldState],
) -> Unit {
  state.get_ref().val.remove_entity(event.entity)
}

///|
fn explode_nearby_mines(
  explode_mines : @ecs.On[ExplodeMines],
  mines : @ecs.Query[@ecs.Comp[Mine], @ecs.All],
  state : @app.Res[MineWorldState],
  commands : @app.Commands,
) -> Unit {
  let world_state = state.get()
  if !world_state.explosions_enabled {
    return
  }
  let event = explode_mines.event()
  for entity in world_state.get_nearby(event.pos) {
    let mine_comp = mines.get(entity) catch { _ => None }
    guard mine_comp is Some(mine_comp) else { continue }
    let mine = mine_comp.value()
    let distance = mine.pos.sub(event.pos).length()
    if distance < mine.size + event.radius {
      commands.trigger(Explode::{ entity, })
    }
  }
}

///|
fn explode_mine(
  explode : @ecs.On[Explode],
  mines : @ecs.Query[@ecs.Comp[Mine], @ecs.All],
  commands : @app.Commands,
) -> Unit raise {
  guard explode.entity() is Some(entity) else { return }
  guard mines.get(entity) is Some(mine_comp) else { return }
  let mine = mine_comp.value()
  commands.entity(entity).despawn()
  commands.trigger(ExplodeMines::{ pos: mine.pos, radius: mine.size + 8.0F })
}

///|
fn toggle_explosions(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  state : @app.ResMut[MineWorldState],
) -> Unit {
  if keyboard_input.just_pressed(Space) {
    let state_ref = state.get_ref()
    state_ref.val.explosions_enabled = !state_ref.val.explosions_enabled
    let label = if state_ref.val.explosions_enabled {
      "enabled"
    } else {
      "disabled"
    }
    @app.log_info("Mine explosions \{label}")
  }
}

///|
fn handle_click(
  pointer : @app.OnPointer[@app.PointerDown],
  windows : @ecs.Query[@ecs.Comp[@window.Window], @ecs.All],
  commands : @app.Commands,
) -> Unit {
  let pos = pointer_world_position(pointer, windows) catch { _ => None }
  guard pos is Some(pos) else { return }
  commands.trigger(ExplodeMines::{ pos, radius: 1.0F })
}

///|
fn draw_mines(
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
  mines : @ecs.Query[@ecs.Comp[Mine], @ecs.All],
) -> Unit {
  try! mines.view(fn(_query_entity, mine_comp) {
    let mine = mine_comp.value()
    ignore(
      gizmos
      .circle_2d(
        @sprite.Isometry2d::new(mine.pos, 0.0F),
        mine.size,
        mine_color(mine.size),
      )
      .resolution(24),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .init_resource(MineWorldState::default)
  .add_startup_system_param(setup)
  .add_system_param2(draw_mines)
  .add_system_param2(toggle_explosions)
  .add_pointer_observer3(handle_click)
  .add_component_observer3(on_add_mine)
  .add_component_observer2(on_remove_mine)
  .add_observer4(explode_nearby_mines)
  .run()
}
