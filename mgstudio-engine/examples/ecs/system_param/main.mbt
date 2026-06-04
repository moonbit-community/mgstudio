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
struct Player {}

///|
struct PlayerCount {
  value : Int
}

///|
fn PlayerCount::value(self : PlayerCount) -> Int {
  self.value
}

///|
struct PlayerCounter[P0, P1] {
  players : P0
  count : P1
  players_state : @app.SystemParamState[P0]
  count_state : @app.SystemParamState[P1]
}

///|
type PlayerCounterParam = PlayerCounter[
  @ecs.Query[@ecs.Comp[Player], @ecs.All],
  @app.ResMut[PlayerCount],
]

///|
let player_key : @ecs.ComponentKey[Player] = @ecs.register_component(
  debug_name="examples.ecs.system_param.Player",
)

///|
let player_count_key : @ecs.ResourceKey[PlayerCount] = @ecs.register_resource(
  debug_name="examples.ecs.system_param.PlayerCount",
)

///|
impl @ecs.Component for Player with fn component() {
  player_key
}

///|
impl @app.Resource for PlayerCount with fn resource() {
  player_count_key
}

///|
impl[P0 : @app.SystemParam, P1 : @app.SystemParam] @app.SystemParam for PlayerCounter[
  P0,
  P1,
] with fn init_state(world) {
  let players_state = P0::init_state(world)
  let count_state = P1::init_state(world)
  @app.SystemParamState::new(
    fn() raise {
      PlayerCounter::{
        players: P0::get(players_state),
        count: P1::get(count_state),
        players_state,
        count_state,
      }
    },
    fn(value : PlayerCounter[P0, P1]) {
      P0::store(value.players, value.players_state)
      P1::store(value.count, value.count_state)
    },
  )
}

///|
impl[P0 : @app.SystemParam, P1 : @app.SystemParam] @app.SystemParam for PlayerCounter[
  P0,
  P1,
] with fn get(state) {
  state.get()
}

///|
impl[P0 : @app.SystemParam, P1 : @app.SystemParam] @app.SystemParam for PlayerCounter[
  P0,
  P1,
] with fn store(self, state) {
  state.store(self)
}

///|
fn PlayerCounterParam::count_players(self : PlayerCounterParam) -> Int {
  let count = self.players.count()
  self.count.set(PlayerCount::{ value: count })
  self.count.get().value()
}

///|
fn spawn(commands : @app.Commands) -> Unit {
  let player_a = commands.spawn_empty()
  commands.entity(player_a).insert_component(Player::{  })

  let player_b = commands.spawn_empty()
  commands.entity(player_b).insert_component(Player::{  })

  let player_c = commands.spawn_empty()
  commands.entity(player_c).insert_component(Player::{  })
}

///|
fn count_players(counter : PlayerCounterParam) -> Unit {
  let count = counter.count_players()
  println("\{count} players in the game")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(PlayerCount::{ value: 0 })
  .add_systems(@app.Startup, @app.system_config_param(spawn))
  .add_systems(@app.Update, @app.system_config_param(count_players))
  .run()
}
