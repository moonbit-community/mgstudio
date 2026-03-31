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
const ATTACK_INTERVAL_SECONDS : Float = 0.2F

///|
struct HitPoints {
  mut value : Int
} derive(Show)

///|
let hit_points_component_key : @ecs.ComponentKey[HitPoints] = @ecs.register_component(
  debug_name="examples.ecs.observer_propagation.HitPoints",
)

///|
pub impl @ecs.Component for HitPoints with component() {
  hit_points_component_key
}

///|
struct Armor {
  value : Int
} derive(Show)

///|
let armor_component_key : @ecs.ComponentKey[Armor] = @ecs.register_component(
  debug_name="examples.ecs.observer_propagation.Armor",
)

///|
pub impl @ecs.Component for Armor with component() {
  armor_component_key
}

///|
struct Attack {
  mut damage : Int
  mut entity : @core.Entity
}

///|
let attack_event_key : @ecs.EventKey[Attack] = @ecs.register_event(
  debug_name="examples.ecs.observer_propagation.Attack",
)

///|
pub impl @ecs.TriggerEvent for Attack with observer_event() {
  attack_event_key
}

///|
pub impl @ecs.TriggerEvent for Attack with observer_entity(self) {
  Some(self.entity)
}

///|
pub impl @ecs.TriggerEvent for Attack with set_observer_entity(
  event_ref,
  entity,
) {
  event_ref.val.entity = entity
}

///|
pub impl @ecs.TriggerEvent for Attack with auto_propagate(_self) {
  true
}

///|
pub impl @ecs.TriggerEvent for Attack with debug_name() {
  "Attack"
}

///|
struct AttackSchedule {
  mut accumulator : Float
  mut next_attack_index : Int
}

///|
let attack_schedule_key : @ecs.ResourceKey[AttackSchedule] = @ecs.register_resource(
  debug_name="examples.ecs.observer_propagation.AttackSchedule",
)

///|
pub impl @app.Resource for AttackSchedule with resource() {
  attack_schedule_key
}

///|
pub impl Default for AttackSchedule with default() {
  { accumulator: 0.0F, next_attack_index: 0 }
}

///|
fn setup(commands : @app.Commands) -> Unit {
  let goblin = commands.spawn(
    (@ecs.Name::new("Goblin"), HitPoints::{ value: 50 }),
  )
  ignore(commands.entity(goblin).observe3(take_damage))

  let helmet = commands.spawn(
    (
      @ecs.Name::new("Helmet"),
      Armor::{ value: 5 },
      @hierarchy.Parent::new(goblin),
    ),
  )
  ignore(commands.entity(helmet).observe2(block_attack))

  let socks = commands.spawn(
    (
      @ecs.Name::new("Socks"),
      Armor::{ value: 10 },
      @hierarchy.Parent::new(goblin),
    ),
  )
  ignore(commands.entity(socks).observe2(block_attack))

  let shirt = commands.spawn(
    (
      @ecs.Name::new("Shirt"),
      Armor::{ value: 15 },
      @hierarchy.Parent::new(goblin),
    ),
  )
  ignore(commands.entity(shirt).observe2(block_attack))
}

///|
fn attack_armor(
  time : @app.Res[@time.Time[Unit]],
  schedule : @app.ResMut[AttackSchedule],
  armors : @ecs.Query[@core.Entity, @ecs.With[Armor]],
  commands : @app.Commands,
) -> Unit {
  let entities : Array[@core.Entity] = []
  try! armors.view(fn(_query_entity, entity) { entities.push(entity) })
  if entities.length() == 0 {
    return
  }

  let schedule_ref = schedule.get_ref()
  schedule_ref.val.accumulator = schedule_ref.val.accumulator +
    time.get().delta_seconds()
  if schedule_ref.val.accumulator < ATTACK_INTERVAL_SECONDS {
    return
  }
  schedule_ref.val.accumulator = 0.0F

  let attack_index = schedule_ref.val.next_attack_index % entities.length()
  schedule_ref.val.next_attack_index = schedule_ref.val.next_attack_index + 1
  let damage = 4 + schedule_ref.val.next_attack_index * 3 % 18
  let entity = entities[attack_index]
  commands.trigger(Attack::{ damage, entity })
  @app.log_info("Attack launched for " + damage.to_string() + " damage")
}

///|
fn attack_hits(
  attack : @ecs.On[Attack],
  names : @ecs.Query[@ecs.Comp[@ecs.Name], @ecs.All],
) -> Unit {
  guard attack.entity() is Some(entity) else { return }
  if (names.get(entity) catch { _ => None }) is Some(name_comp) {
    @app.log_info("Attack hit " + name_comp.value().as_str())
  }
}

///|
fn block_attack(
  attack : @ecs.On[Attack],
  armor_query : @ecs.Query[(@ecs.Comp[Armor], @ecs.Comp[@ecs.Name]), @ecs.All],
) -> Unit raise {
  guard attack.entity() is Some(entity) else { return }
  guard armor_query.get(entity) is Some((armor_comp, name_comp)) else { return }
  let armor = armor_comp.value()
  let damage = attack.event().damage - armor.value
  if damage > 0 {
    attack.get_ref().val.damage = damage
    @app.log_info(
      damage.to_string() +
      " damage passed through " +
      name_comp.value().as_str(),
    )
  } else {
    @app.log_info(
      attack.event().damage.to_string() +
      " damage blocked by " +
      name_comp.value().as_str(),
    )
    attack.propagate(false)
    @app.log_info("Propagation halted early")
  }
}

///|
fn take_damage(
  attack : @ecs.On[Attack],
  hit_points : @ecs.Query[(@ecs.Mut[HitPoints], @ecs.Comp[@ecs.Name]), @ecs.All],
  commands : @app.Commands,
) -> Unit raise {
  guard attack.entity() is Some(entity) else { return }
  guard hit_points.get(entity) is Some((hit_points_mut, name_comp)) else {
    return
  }
  let hp_ref = hit_points_mut.get_ref()
  hp_ref.val.value = hp_ref.val.value - attack.event().damage
  if hp_ref.val.value > 0 {
    @app.log_info(
      name_comp.value().as_str() +
      " has " +
      hp_ref.val.value.to_string() +
      " HP",
    )
    return
  }

  @app.log_warn(name_comp.value().as_str() + " has died")
  commands.entity(entity).despawn()
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .init_resource(AttackSchedule::default)
  .add_startup_system_param(setup)
  .add_system_param4(attack_armor)
  .add_observer2(attack_hits)
  .run()
}
