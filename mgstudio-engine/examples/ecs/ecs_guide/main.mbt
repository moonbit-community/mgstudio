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
struct Player {
  name : String
}

///|
struct Score {
  mut value : Int
}

///|
pub(all) enum PlayerStreak {
  Hot(Int)
  None
  Cold(Int)
}

///|
struct GameState {
  mut current_round : Int
  mut total_players : Int
  mut winning_player : String?
}

///|
struct GameRules {
  winning_score : Int
  max_rounds : Int
  max_players : Int
}

///|
let player_key : @ecs.ComponentKey[Player] = @ecs.register_component(
  debug_name="examples.ecs.ecs_guide.player",
)

///|
let score_key : @ecs.ComponentKey[Score] = @ecs.register_component(
  debug_name="examples.ecs.ecs_guide.score",
)

///|
let player_streak_key : @ecs.ComponentKey[PlayerStreak] = @ecs.register_component(
  debug_name="examples.ecs.ecs_guide.player_streak",
)

///|
let game_state_key : @ecs.ResourceKey[GameState] = @ecs.register_resource(
  debug_name="examples.ecs.ecs_guide.game_state",
)

///|
let game_rules_key : @ecs.ResourceKey[GameRules] = @ecs.register_resource(
  debug_name="examples.ecs.ecs_guide.game_rules",
)

///|
let before_round_set : @app.SystemSet = @app.system_set(
  "examples.ecs.ecs_guide.before_round",
)

///|
let round_set : @app.SystemSet = @app.system_set("examples.ecs.ecs_guide.round")

///|
let after_round_set : @app.SystemSet = @app.system_set(
  "examples.ecs.ecs_guide.after_round",
)

///|
pub impl @ecs.Component for Player with component() {
  player_key
}

///|
pub impl @ecs.Component for Score with component() {
  score_key
}

///|
pub impl @ecs.Component for PlayerStreak with component() {
  player_streak_key
}

///|
pub impl @app.Resource for GameState with resource() {
  game_state_key
}

///|
pub impl @app.Resource for GameRules with resource() {
  game_rules_key
}

///|
impl Default for GameState with default() {
  GameState::{ current_round: 0, total_players: 0, winning_player: None }
}

///|
fn streak_text(streak : PlayerStreak) -> String {
  match streak {
    Hot(rounds) => "\{rounds.to_string()} round hot streak"
    None => "0 round streak"
    Cold(rounds) => "\{rounds.to_string()} round cold streak"
  }
}

///|
fn player_name(index : Int) -> String {
  "Player \{index.to_string()}"
}

///|
fn print_message_system(_world : @ecs.World) -> Unit {
  println("This game is fun!")
}

///|
fn new_round_system(
  game_rules : @app.Res[GameRules],
  game_state : @app.ResMut[GameState],
) -> Unit {
  let state_ref = game_state.get_ref()
  state_ref.val.current_round = state_ref.val.current_round + 1
  println(
    "Begin round \{state_ref.val.current_round.to_string()} of \{game_rules.get().max_rounds.to_string()}",
  )
}

///|
fn score_system(
  game_state : @app.Res[GameState],
  query : @ecs.Query[
    (@ecs.Comp[Player], @ecs.Mut[Score], @ecs.Mut[PlayerStreak]),
    @ecs.All,
  ],
) -> Unit {
  let round = game_state.get().current_round
  try! query.view(fn(_entity, item) {
    let (player, score, streak) = item
    let player_name = player.value().name
    let scored_a_point = if player_name == "Alice" {
      true
    } else {
      (round + player_name.length() + score.value().value) % 3 == 0
    }
    let score_ref = score.get_ref()
    let streak_ref = streak.get_ref()
    if scored_a_point {
      score_ref.val.value = score_ref.val.value + 1
      streak_ref.val = match streak_ref.val {
        Hot(count) => Hot(count + 1)
        Cold(_) => Hot(1)
        None => Hot(1)
      }
      println(
        "\{player_name} scored a point! Their score is: \{score_ref.val.value.to_string()} (\{streak_text(streak_ref.val)})",
      )
    } else {
      streak_ref.val = match streak_ref.val {
        Hot(_) => Cold(1)
        None => Cold(1)
        Cold(count) => Cold(count + 1)
      }
      println(
        "\{player_name} did not score a point! Their score is: \{score_ref.val.value.to_string()} (\{streak_text(streak_ref.val)})",
      )
    }
  })
}

///|
fn score_check_system(
  game_rules : @app.Res[GameRules],
  game_state : @app.ResMut[GameState],
  query : @ecs.Query[(@ecs.Comp[Player], @ecs.Comp[Score]), @ecs.All],
) -> Unit {
  let winning_score = game_rules.get().winning_score
  let state_ref = game_state.get_ref()
  try! query.view(fn(_entity, item) {
    let (player, score) = item
    if score.value().value >= winning_score &&
      state_ref.val.winning_player is None {
      state_ref.val.winning_player = Some(player.value().name)
    }
  })
}

///|
fn game_over_system(
  game_rules : @app.Res[GameRules],
  game_state : @app.Res[GameState],
  app_exit_writer : @ecs.MessageWriter[@app.AppExit],
) -> Unit {
  if game_state.get().winning_player is Some(player) {
    println("\{player} won the game!")
    ignore(app_exit_writer.write(@app.AppExit::Success))
  } else if game_state.get().current_round >= game_rules.get().max_rounds {
    println("Ran out of rounds. Nobody wins!")
    ignore(app_exit_writer.write(@app.AppExit::Success))
  }
}

///|
fn startup_system(
  commands : @app.Commands,
  game_state : @app.ResMut[GameState],
) -> Unit {
  commands.insert_resource(GameRules::{
    winning_score: 4,
    max_rounds: 10,
    max_players: 4,
  })
  ignore(
    commands.spawn_batch([
      (Player::{ name: "Alice" }, Score::{ value: 0 }, PlayerStreak::None),
      (Player::{ name: "Bob" }, Score::{ value: 0 }, PlayerStreak::None),
    ]),
  )
  game_state.get_ref().val.total_players = 2
}

///|
fn new_player_system(
  commands : @app.Commands,
  game_rules : @app.Res[GameRules],
  game_state : @app.ResMut[GameState],
) -> Unit {
  let state_ref = game_state.get_ref()
  if state_ref.val.current_round % 2 == 1 &&
    state_ref.val.total_players < game_rules.get().max_players {
    state_ref.val.total_players = state_ref.val.total_players + 1
    let next_name = player_name(state_ref.val.total_players)
    ignore(
      commands.spawn(
        (Player::{ name: next_name }, Score::{ value: 0 }, PlayerStreak::None),
      ),
    )
    println(
      "Player \{state_ref.val.total_players.to_string()} joined the game!",
    )
  }
}

///|
fn exclusive_player_system(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(game_state_key)) is Some(game_state) else {
    return
  }
  guard (try! world.get_resource(game_rules_key)) is Some(game_rules) else {
    return
  }
  if game_state.current_round == 2 &&
    game_state.total_players < game_rules.max_players {
    let next_total = game_state.total_players + 1
    let entity = world.spawn_empty()
    ignore(
      try! world
      .entity_mut(entity)
      .insert(
        (
          Player::{ name: player_name(next_total) },
          Score::{ value: 0 },
          PlayerStreak::None,
        ),
      ),
    )
    let game_state_ref = match
      (try! world.get_resource_ref_mut(game_state_key)) {
      Some(value) => value
      None => return
    }
    game_state_ref.val.total_players = next_total
    println("Player \{next_total.to_string()} has joined the game!")
  }
}

///|
fn print_at_end_round(counter : @app.Local[Int]) -> Unit {
  let counter_ref = counter.get_ref()
  counter_ref.val = counter_ref.val + 1
  println("In set 'Last' for the \{counter_ref.val.to_string()}th time")
  println("")
}

///|
fn main {
  let new_round_system_config : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(new_round_system),
  )
  let new_player_system_config : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(new_player_system),
  )
  let before_round_chain : @app.SystemConfig[@ecs.World] = (
      new_round_system_config, new_player_system_config,
    )
    |> @app.chain()
  let score_check_system_config : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(score_check_system),
  )
  let game_over_system_config : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(game_over_system),
  )
  let after_round_chain : @app.SystemConfig[@ecs.World] = (
      score_check_system_config, game_over_system_config,
    )
    |> @app.chain()

  @app.App::new(@ecs.World::new())
  .init_resource(GameState::default)
  .add_plugins([
    @app.schedule_runner_plugin(@app.ScheduleRunnerPlugin::run_loop(0.05F)),
  ])
  .add_systems(@app.Startup, @app.system(@app.system_param2(startup_system)))
  .add_systems(@app.Update, @app.system(print_message_system))
  .add_systems(@app.Last, @app.system(@app.system_param(print_at_end_round)))
  .configure_set(@app.Update, before_round_set, before=[round_set])
  .configure_set(@app.Update, round_set, before=[after_round_set])
  .add_systems(@app.Update, before_round_chain.in_set(before_round_set))
  .add_systems(
    @app.Update,
    @app.system(exclusive_player_system).in_set(before_round_set),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(score_system)).in_set(round_set),
  )
  .add_systems(@app.Update, after_round_chain.in_set(after_round_set))
  .run()
}
