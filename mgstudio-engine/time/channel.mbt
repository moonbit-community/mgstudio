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
//
// Adapted from Bevy's `bevy_time` crate.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
pub(all) struct TimeChannel {
  priv capacity : Int
  priv queue : Array[@core.Instant]
}

///|
fn TimeChannel::bounded(capacity : Int) -> TimeChannel {
  { capacity: capacity.max(1), queue: [] }
}

///|
pub struct TimeReceiver {
  channel : TimeChannel
  mut has_received_time : Bool
}

///|
pub struct TimeSender {
  channel : TimeChannel
}

///|
pub suberror TimeSendError {
  Full
}

///|
pub let time_receiver_resource_key : @ecs.ResourceKey[TimeReceiver] = @ecs.register_resource(
  debug_name="mgstudio_time::TimeReceiver",
)

///|
pub let time_sender_resource_key : @ecs.ResourceKey[TimeSender] = @ecs.register_resource(
  debug_name="mgstudio_time::TimeSender",
)

///|
pub impl @app.Resource for TimeReceiver with fn resource() {
  time_receiver_resource_key
}

///|
pub impl @app.Resource for TimeSender with fn resource() {
  time_sender_resource_key
}

///|
pub fn create_time_channels() -> (TimeSender, TimeReceiver) {
  let channel = TimeChannel::bounded(2)
  ({ channel, }, { channel, has_received_time: false })
}

///|
pub fn TimeSender::try_send(
  self : TimeSender,
  instant : @core.Instant,
) -> Unit raise TimeSendError {
  if self.channel.queue.length() >= self.channel.capacity {
    raise Full
  }
  self.channel.queue.push(instant)
}

///|
pub fn TimeReceiver::try_recv(self : TimeReceiver) -> @core.Instant? {
  if self.channel.queue.is_empty() {
    None
  } else {
    Some(self.channel.queue.remove(0))
  }
}

///|
fn time_receive_sent_instant(world : @ecs.World) -> @core.Instant? {
  match world.get_resource(time_receiver_resource_key) {
    Some(receiver) =>
      match receiver.try_recv() {
        Some(instant) => {
          receiver.has_received_time = true
          Some(instant)
        }
        None => {
          if receiver.has_received_time {
            @app.log_warn(
              "time_system did not receive the time from the render world! Calculations depending on the time may be incorrect.",
            )
          }
          None
        }
      }
    None => None
  }
}
