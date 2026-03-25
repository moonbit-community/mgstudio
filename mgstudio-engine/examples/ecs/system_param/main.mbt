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

///|
struct Player {}

///|
struct PlayerCount {
  mut value : Int
}

///|
struct PlayerCounter[P0, P1] {
  players : P0
  count : P1
  players_state : Ref[Json]
  count_state : Ref[Json]
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
impl @ecs.Component for Player with component() {
  player_key
}

///|
impl @app.Resource for PlayerCount with resource() {
  player_count_key
}

///|
fn player_counter_decode_state(state : Ref[Json]) -> (Json, Json) {
  try @json.from_json(state.val) catch {
    _ => (Json::null(), Json::null())
  } noraise {
    value => value
  }
}

///|
impl[P0 : @app.SystemParam, P1 : @app.SystemParam] @app.SystemParam for PlayerCounter[
  P0,
  P1,
] with init_state(world) {
  (P0::init_state(world), P1::init_state(world)).to_json()
}

///|
impl[P0 : @app.SystemParam, P1 : @app.SystemParam] @app.SystemParam for PlayerCounter[
  P0,
  P1,
] with get(state) {
  let (players_state, count_state) = player_counter_decode_state(state)
  let players_state_ref = Ref::new(players_state)
  let count_state_ref = Ref::new(count_state)
  PlayerCounter::{
    players: P0::get(players_state_ref),
    count: P1::get(count_state_ref),
    players_state: players_state_ref,
    count_state: count_state_ref,
  }
}

///|
impl[P0 : @app.SystemParam, P1 : @app.SystemParam] @app.SystemParam for PlayerCounter[
  P0,
  P1,
] with store(self, state) {
  P0::store(self.players, self.players_state)
  P1::store(self.count, self.count_state)
  state.val = (self.players_state.val, self.count_state.val).to_json()
}

///|
fn PlayerCounterParam::count_players(self : PlayerCounterParam) -> Int {
  let count_ref = self.count.get_ref()
  count_ref.val.value = self.players.count()
  count_ref.val.value
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
  .add_systems(@app.Startup, @app.system(@app.system_param(spawn)))
  .add_systems(@app.Update, @app.system(@app.system_param(count_players)))
  .run()
}
