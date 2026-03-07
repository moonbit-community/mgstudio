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
/// Port of `bevy/examples/audio/soundtrack.rs`.

///|
const STATE_CHANGE_SECONDS : Float = 10.0F

///|
const FADE_TIME : Float = 2.0F

///|
pub(all) enum GameState {
  Peaceful
  Battle
}

///|
priv struct GameStateTimer {
  timer : @time.Timer
}

///|
priv struct SoundtrackPlayer {
  track_list : Array[@asset.Handle[@audio.AudioSource]]
}

///|
priv struct TrackChangePending {
  changed : Bool
}

///|
priv struct FadeIn {}

///|
priv struct FadeOut {}

///|
let game_state_resource_key : @ecs.ResourceKey[GameState] = @ecs.register_resource(
  debug_name="examples.audio.soundtrack.GameState",
)

///|
let game_state_timer_resource_key : @ecs.ResourceKey[GameStateTimer] = @ecs.register_resource(
  debug_name="examples.audio.soundtrack.GameStateTimer",
)

///|
let soundtrack_player_resource_key : @ecs.ResourceKey[SoundtrackPlayer] = @ecs.register_resource(
  debug_name="examples.audio.soundtrack.SoundtrackPlayer",
)

///|
let track_change_pending_resource_key : @ecs.ResourceKey[TrackChangePending] = @ecs.register_resource(
  debug_name="examples.audio.soundtrack.TrackChangePending",
)

///|
let fade_in_component_key : @ecs.ComponentKey[FadeIn] = @ecs.register_component(
  debug_name="examples.audio.soundtrack.FadeIn",
)

///|
let fade_out_component_key : @ecs.ComponentKey[FadeOut] = @ecs.register_component(
  debug_name="examples.audio.soundtrack.FadeOut",
)

///|
impl @app.Resource for GameState with resource() {
  game_state_resource_key
}

///|
impl @app.Resource for GameStateTimer with resource() {
  game_state_timer_resource_key
}

///|
impl @app.Resource for SoundtrackPlayer with resource() {
  soundtrack_player_resource_key
}

///|
impl @app.Resource for TrackChangePending with resource() {
  track_change_pending_resource_key
}

///|
impl @ecs.Component for FadeIn with component() {
  fade_in_component_key
}

///|
impl @ecs.Component for FadeOut with component() {
  fade_out_component_key
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(cycle_game_state))
  .add_systems(@app.Update, @app.system(change_track))
  .add_systems(@app.Update, @app.system(fade_in))
  .add_systems(@app.Update, @app.system(fade_out))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(GameState::resource(), GameState::Peaceful)
  world.insert_resource(GameStateTimer::resource(), GameStateTimer::{
    timer: @time.Timer::from_seconds(
      STATE_CHANGE_SECONDS,
      @time.TimerMode::Repeating,
    ),
  })
  world.insert_resource(TrackChangePending::resource(), TrackChangePending::{
    changed: true,
  })

  let asset_server = @asset.AssetServer::new()
  guard @audio.audio_source_load(
      world, asset_server, "sounds/Mysterious acoustic guitar.ogg",
    )
    is Some(track_1) else {
    return
  }
  guard @audio.audio_source_load(
      world, asset_server, "sounds/Epic orchestra music.ogg",
    )
    is Some(track_2) else {
    return
  }
  world.insert_resource(SoundtrackPlayer::resource(), SoundtrackPlayer::{
    track_list: [track_1, track_2],
  })

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
}

///|
fn cycle_game_state(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(GameStateTimer::resource()))
    is Some(timer_state) else {
    return
  }
  let next_timer = timer_state.timer.tick(@time.time_delta())
  world.insert_resource(GameStateTimer::resource(), GameStateTimer::{
    timer: next_timer,
  })
  if !next_timer.just_finished() {
    return
  }

  guard (try! world.get_resource(GameState::resource())) is Some(game_state) else {
    return
  }
  let next_state = match game_state {
    Battle => Peaceful
    Peaceful => Battle
  }
  world.insert_resource(GameState::resource(), next_state)
  world.insert_resource(TrackChangePending::resource(), TrackChangePending::{
    changed: true,
  })
}

///|
fn change_track(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(TrackChangePending::resource()))
    is Some(pending) else {
    return
  }
  if !pending.changed {
    return
  }

  world.insert_resource(TrackChangePending::resource(), TrackChangePending::{
    changed: false,
  })

  let tick = world.read_change_tick()
  let audio_sinks = world.component(@audio.ecs_key_audio_sink)
  audio_sinks.for_each(fn(entity : @core.Entity, _sink : @audio.AudioSink) {
    if !world.component(fade_out_component_key).contains(entity) {
      world
      .component(fade_out_component_key)
      .insert(entity, FadeOut::{  }, tick)
    }
    if world.component(fade_in_component_key).contains(entity) {
      world.component(fade_in_component_key).remove(entity) |> ignore
    }
  })

  guard (try! world.get_resource(SoundtrackPlayer::resource())) is Some(player) else {
    return
  }
  guard (try! world.get_resource(GameState::resource())) is Some(game_state) else {
    return
  }
  let track = match game_state {
    Peaceful => player.track_list[0]
    Battle => player.track_list[1]
  }

  let entity = world.spawn_empty()
  world
  .component(@audio.ecs_key_audio_source_player)
  .insert(entity, @audio.AudioPlayer::new(track), tick)
  world
  .component(@audio.ecs_key_playback_settings)
  .insert(
    entity,
    @audio.PlaybackSettings::looped().with_volume(@audio.Volume::silent()),
    tick,
  )
  world.component(fade_in_component_key).insert(entity, FadeIn::{  }, tick)
}

///|
fn fade_in(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(GameStateTimer::resource()))
    is Some(timer_state) else {
    return
  }

  let factor = timer_state.timer.elapsed_secs() / FADE_TIME
  let fade_in_store = world.component(fade_in_component_key)
  let sink_store = world.component(@audio.ecs_key_audio_sink)
  let entities : Array[@core.Entity] = []
  fade_in_store.for_each(fn(entity : @core.Entity, _marker : FadeIn) {
    if sink_store.contains(entity) {
      entities.push(entity)
    }
  })

  if entities.length() == 0 {
    return
  }

  let tick = world.read_change_tick()
  for entity in entities {
    sink_store.update(entity, tick, fn(sink : @audio.AudioSink) {
      sink.set_volume(
        @audio.Volume::silent().fade_towards(
          @audio.Volume::Linear(1.0F),
          factor,
        ),
      )
    })
    |> ignore
    if factor >= 1.0F {
      sink_store.update(entity, tick, fn(sink : @audio.AudioSink) {
        sink.set_volume(@audio.Volume::Linear(1.0F))
      })
      |> ignore
      fade_in_store.remove(entity) |> ignore
    }
  }
}

///|
fn fade_out(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(GameStateTimer::resource()))
    is Some(timer_state) else {
    return
  }

  let factor = timer_state.timer.elapsed_secs() / FADE_TIME
  let fade_out_store = world.component(fade_out_component_key)
  let sink_store = world.component(@audio.ecs_key_audio_sink)
  let entities : Array[@core.Entity] = []
  fade_out_store.for_each(fn(entity : @core.Entity, _marker : FadeOut) {
    if sink_store.contains(entity) {
      entities.push(entity)
    }
  })

  if entities.length() == 0 {
    return
  }

  let tick = world.read_change_tick()
  for entity in entities {
    sink_store.update(entity, tick, fn(sink : @audio.AudioSink) {
      sink.set_volume(
        @audio.Volume::Linear(1.0F).fade_towards(
          @audio.Volume::silent(),
          factor,
        ),
      )
    })
    |> ignore
    if factor >= 1.0F {
      world.despawn(entity) catch {
        _ => ()
      }
    }
  }
}
