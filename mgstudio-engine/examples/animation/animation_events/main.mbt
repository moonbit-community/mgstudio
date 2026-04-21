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
struct MessageText {}

///|
struct SetMessage {
  observer_entity : @core.Entity?
  value : String
  palette : MessagePalette
}

///|
pub(all) enum MessagePalette {
  None
  Hello
  Bye
} derive(Eq, Debug)

///|
struct MessageFade {
  palette : MessagePalette
}

///|
let message_text_key : @ecs.ComponentKey[MessageText] = @ecs.register_component(
  debug_name="examples.animation.animation_events.message_text",
)

///|
let message_fade_key : @ecs.ComponentKey[MessageFade] = @ecs.register_component(
  debug_name="examples.animation.animation_events.message_fade",
)

///|
let set_message_event_key : @ecs.EventKey[SetMessage] = @ecs.register_event(
  debug_name="examples.animation.animation_events.set_message",
)

///|
pub impl @ecs.Component for MessageText with component() {
  message_text_key
}

///|
pub impl @ecs.Component for MessageFade with component() {
  message_fade_key
}

///|
pub impl @animation.AnimationEvent for SetMessage with animation_event_marker(
  _self,
) {

}

///|
pub impl @ecs.TriggerEvent for SetMessage with observer_event() {
  set_message_event_key
}

///|
pub impl @ecs.TriggerEvent for SetMessage with observer_entity(self) {
  self.observer_entity
}

///|
pub impl @ecs.TriggerEvent for SetMessage with set_observer_entity(self, entity) {
  SetMessage::{
    observer_entity: Some(entity),
    value: self.value,
    palette: self.palette,
  }
}

///|
pub impl @ecs.TriggerEvent for SetMessage with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for SetMessage with debug_name() {
  "SetMessage"
}

///|
fn SetMessage::new(value : String, palette : MessagePalette) -> SetMessage {
  { observer_entity: None, value, palette }
}

///|
fn message_color(palette : MessagePalette, alpha : Float) -> @color.Color {
  match palette {
    None => @color.Color::srgba(0.0F, 0.0F, 0.0F, alpha)
    Hello => @color.Color::srgba(0.94F, 0.97F, 1.0F, alpha)
    Bye => @color.Color::srgba(0.86F, 0.08F, 0.24F, alpha)
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  @sprite.Camera2dBundle::new(
    @sprite.Camera::new(@color.Color::black()),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let message_entity = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(message_entity)
    .insert(
      (
        MessageText::{  },
        MessageFade::{ palette: MessagePalette::None },
        @text.Text2d::default(),
        @text.TextFont::default().with_font_size(@text.FontSize::Px(119.0F)),
        @text.TextColor::new(message_color(MessagePalette::None, 0.0F)),
      ),
    ),
  )
  ignore(
    try! world
    .entity_mut(message_entity)
    .insert_component(@transform.Transform::identity()),
  )

  let clip = @animation.AnimationClip::new()
    .set_duration(2.0F)
    .add_typed_event(0.0F, SetMessage::new("HELLO", MessagePalette::Hello))
    .add_typed_event(1.0F, SetMessage::new("BYE", MessagePalette::Bye))
  let clip_handle = @animation.animation_clip_add(clip)
  let (graph, animation_index) = @animation.AnimationGraph::from_clip(
    clip_handle,
  )
  let graph_handle = @animation.animation_graph_add(graph)
  let player = @animation.AnimationPlayer::default()
  player.play(animation_index).repeat() |> ignore

  let player_entity = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(player_entity)
    .insert((@animation.AnimationGraphHandle::new(graph_handle), player)),
  )
}

///|
fn on_set_message(
  set_message : @ecs.On[SetMessage],
  text : @app.Single[
    (@ecs.Mut[@text.Text2d], @ecs.Mut[@text.TextColor], @ecs.Mut[MessageFade]),
    @ecs.With[MessageText],
  ],
) -> Unit {
  let event = set_message.event()
  let (text2d, color, fade) = text.get()
  text2d.set(@text.Text2d::new(event.value))
  fade.set(MessageFade::{ palette: event.palette })
  color.set(@text.TextColor::new(message_color(event.palette, 1.0F)))
}

///|
fn animate_text_opacity(
  text : @ecs.Query[
    (@ecs.Mut[@text.TextColor], @ecs.Comp[MessageFade]),
    @ecs.With[MessageText],
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! text.view(fn(_entity, entry) {
    let (color, fade) = entry
    let current_alpha = color.value().color.alpha()
    let next_alpha = if current_alpha > delta {
      current_alpha - delta
    } else {
      0.0F
    }
    color.set(
      @text.TextColor::new(message_color(fade.value().palette, next_alpha)),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(animate_text_opacity)),
  )
  .add_observer2(on_set_message)
  .run()
}
