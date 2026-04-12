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
// Bevy source: `bevy/crates/bevy_utils/src/buffered_channel.rs`.
// MoonBit adaptation of Bevy's buffered-channel utility.

///|
pub type BufferedChannelBuffer[T] = Array[T]

///|
pub fn[T] buffered_channel_new_buffer() -> BufferedChannelBuffer[T] {
  []
}

///|
pub struct BufferedChannel[T] {
  mut chunk_size : Int
  queued_chunks : Array[Array[T]]
  pooled_chunks : Array[Array[T]]
}

///|
pub struct BufferedReceiver[T] {
  channel : BufferedChannel[T]
}

///|
pub struct BufferedSender[T] {
  channel : BufferedChannel[T]
  mut buffer : Array[T]
}

///|
pub fn[T] BufferedChannel::new(chunk_size? : Int = 1024) -> BufferedChannel[T] {
  BufferedChannel::{
    chunk_size: if chunk_size <= 0 { 1 } else { chunk_size },
    queued_chunks: [],
    pooled_chunks: [],
  }
}

///|
pub fn[T] BufferedChannel::default() -> BufferedChannel[T] {
  BufferedChannel::new()
}

///|
pub fn[T] BufferedChannel::chunk_size(self : BufferedChannel[T]) -> Int {
  self.chunk_size
}

///|
pub fn[T] BufferedChannel::set_chunk_size(self : BufferedChannel[T], chunk_size : Int) -> Unit {
  self.chunk_size = if chunk_size <= 0 { 1 } else { chunk_size }
}

///|
fn[T] buffered_channel_take_chunk_buffer(channel : BufferedChannel[T]) -> Array[T] {
  match channel.pooled_chunks.pop() {
    Some(buffer) => buffer
    None => []
  }
}

///|
pub fn[T] BufferedChannel::unbounded(
  self : BufferedChannel[T],
) -> (BufferedReceiver[T], BufferedSender[T]) {
  (
    BufferedReceiver::{ channel: self },
    BufferedSender::{ channel: self, buffer: buffered_channel_take_chunk_buffer(self) },
  )
}

///|
pub fn[T] BufferedChannel::bounded(
  self : BufferedChannel[T],
  _cap : Int,
) -> (BufferedReceiver[T], BufferedSender[T]) {
  self.unbounded()
}

///|
pub fn[T] BufferedChannel::queued_chunk_count(self : BufferedChannel[T]) -> Int {
  self.queued_chunks.length()
}

///|
pub fn[T] BufferedSender::send(self : BufferedSender[T], msg : T) -> Unit {
  self.buffer.push(msg)
  if self.buffer.length() >= self.channel.chunk_size {
    self.flush()
  }
}

///|
pub fn[T] BufferedSender::send_many(self : BufferedSender[T], items : Array[T]) -> Unit {
  for item in items {
    self.send(item)
  }
}

///|
pub fn[T] BufferedSender::flush(self : BufferedSender[T]) -> Unit {
  if self.buffer.is_empty() {
    return
  }
  let full_buffer = self.buffer
  self.buffer = buffered_channel_take_chunk_buffer(self.channel)
  self.channel.queued_chunks.push(full_buffer)
}

///|
pub fn[T] BufferedSender::close(self : BufferedSender[T]) -> Unit {
  self.flush()
}

///|
pub fn[T] BufferedReceiver::recv(self : BufferedReceiver[T]) -> Array[T]? {
  self.channel.queued_chunks.pop()
}

///|
pub fn[T] BufferedReceiver::recycle(
  self : BufferedReceiver[T],
  chunk : Array[T],
) -> Unit {
  chunk.clear()
  self.channel.pooled_chunks.push(chunk)
}
