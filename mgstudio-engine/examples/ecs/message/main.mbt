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
/// Port of `bevy/examples/ecs/message.rs`.

///|
struct DealDamage {
  mut amount : Int
} derive(Show)

///|
struct DamageReceived {} derive(Show)

///|
struct ArmorBlockedDamage {} derive(Show)

///|
struct DamageTimer {
  mut timer : @time.Timer
} derive(Show)

///|
let deal_damage_key : @ecs.MessageKey[DealDamage] = @ecs.register_message(
  debug_name="examples.ecs.message.DealDamage",
)

///|
let damage_received_key : @ecs.MessageKey[DamageReceived] = @ecs.register_message(
  debug_name="examples.ecs.message.DamageReceived",
)

///|
let armor_blocked_damage_key : @ecs.MessageKey[ArmorBlockedDamage] = @ecs.register_message(
  debug_name="examples.ecs.message.ArmorBlockedDamage",
)

///|
let damage_timer_key : @ecs.ResourceKey[DamageTimer] = @ecs.register_resource(
  debug_name="examples.ecs.message.DamageTimer",
)

///|
pub impl @ecs.Message for DealDamage with message() {
  deal_damage_key
}

///|
pub impl @ecs.Message for DamageReceived with message() {
  damage_received_key
}

///|
pub impl @ecs.Message for ArmorBlockedDamage with message() {
  armor_blocked_damage_key
}

///|
pub impl @app.Resource for DamageTimer with resource() {
  damage_timer_key
}

///|
pub impl Default for DamageReceived with default() {
  DamageReceived::{  }
}

///|
pub impl Default for ArmorBlockedDamage with default() {
  ArmorBlockedDamage::{  }
}

///|
pub impl Default for DamageTimer with default() {
  { timer: @time.Timer::from_seconds(1.0F, @time.TimerMode::Repeating) }
}

///|
let deal_damage_over_time_set : @app.SystemSet = @app.system_set(
  "examples.ecs.message.deal_damage_over_time",
)

///|
let apply_armor_to_damage_set : @app.SystemSet = @app.system_set(
  "examples.ecs.message.apply_armor_to_damage",
)

///|
let apply_damage_to_health_set : @app.SystemSet = @app.system_set(
  "examples.ecs.message.apply_damage_to_health",
)

///|
fn deal_damage_over_time(
  time : @app.Res[@time.Time[Unit]],
  state : @app.ResMut[DamageTimer],
  deal_damage_writer : @ecs.MessageWriter[DealDamage],
) -> Unit {
  let state_ref = state.get_ref()
  state_ref.val.timer = state_ref.val.timer.tick(time.get().delta())
  if state_ref.val.timer.is_finished() {
    ignore(deal_damage_writer.write(DealDamage::{ amount: 10 }))
  }
}

///|
fn apply_armor_to_damage(
  dmg_messages : @ecs.MessageMutator[DealDamage],
  armor_messages : @ecs.MessageWriter[ArmorBlockedDamage],
) -> Unit {
  for message in (try! dmg_messages.read()) {
    message.val.amount = message.val.amount - 1
    if message.val.amount <= 0 {
      ignore(armor_messages.write(ArmorBlockedDamage::{  }))
    }
  }
}

///|
fn apply_damage_to_health(
  deal_damage_reader : @ecs.MessageReader[DealDamage],
  damaged_received_writer : @ecs.MessageWriter[DamageReceived],
) -> Unit {
  for deal_damage in (try! deal_damage_reader.read()) {
    @app.log_info("Applying " + deal_damage.amount.to_string() + " damage")
    if deal_damage.amount > 0 {
      ignore(damaged_received_writer.write_default())
    }
  }
}

///|
fn play_damage_received_sound(
  damage_received_reader : @ecs.MessageReader[DamageReceived],
) -> Unit {
  for _ in (try! damage_received_reader.read()) {
    @app.log_info("Playing a sound.")
  }
}

///|
fn play_damage_received_particle_effect(
  damage_received_reader : @ecs.MessageReader[DamageReceived],
) -> Unit {
  for _ in (try! damage_received_reader.read()) {
    @app.log_info("Playing particle effect.")
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_message(deal_damage_key)
  .add_message(armor_blocked_damage_key)
  .add_message(damage_received_key)
  .init_resource(DamageTimer::default)
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(deal_damage_over_time)).in_set(
      deal_damage_over_time_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(apply_armor_to_damage)).in_set(
      apply_armor_to_damage_set,
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(apply_damage_to_health)).in_set(
      apply_damage_to_health_set,
    ),
  )
  .configure_set(@app.Update, deal_damage_over_time_set, before=[
    apply_armor_to_damage_set,
  ])
  .configure_set(@app.Update, apply_armor_to_damage_set, before=[
    apply_damage_to_health_set,
  ])
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(play_damage_received_sound)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(play_damage_received_particle_effect)),
  )
  .run()
}
