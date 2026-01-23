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
/// Internal output sink for the DEFLATE encoder.
///
/// Ported from `yazi/src/encode.rs` (Apache-2.0 OR MIT).
priv struct Snapshot {
  pos : Int
  bit_buffer : UInt
  bits_in : Int
}

///|
priv enum SinkKind {
  Vec(Array[Byte])
  Buf(Array[Byte])
}

///|
/// Bit/byte sink for encoder output.
///
/// - Bits are appended LSB-first (DEFLATE bit order).
/// - Vec mode appends into an existing array.
/// - Buf mode writes into a fixed-size buffer and raises `Overflow` on out-of-range.
priv struct Sink {
  kind : SinkKind
  start_pos : Int
  mut pos : Int
  mut bit_buffer : UInt
  mut bits_in : Int
}

///|
fn Sink::new_vec(out : Array[Byte]) -> Sink {
  let start = out.length()
  Sink::{
    kind: SinkKind::Vec(out),
    start_pos: start,
    pos: start,
    bit_buffer: 0,
    bits_in: 0,
  }
}

///|
fn Sink::new_buf(buf : Array[Byte]) -> Sink {
  Sink::{
    kind: SinkKind::Buf(buf),
    start_pos: 0,
    pos: 0,
    bit_buffer: 0,
    bits_in: 0,
  }
}

///|
fn Sink::snapshot(self : Sink) -> Snapshot {
  Snapshot::{
    pos: self.pos,
    bit_buffer: self.bit_buffer,
    bits_in: self.bits_in,
  }
}

///|
fn Sink::restore(self : Sink, snap : Snapshot) -> Unit {
  match self.kind {
    SinkKind::Vec(out) => out.truncate(snap.pos)
    _ => ()
  }
  self.pos = snap.pos
  self.bit_buffer = snap.bit_buffer
  self.bits_in = snap.bits_in
}

///|
fn Sink::written(self : Sink) -> UInt64 {
  (self.pos - self.start_pos).to_uint64()
}

///|
fn Sink::set_bit_buffer(self : Sink, bit_buffer : UInt, bits_in : Int) -> Unit {
  self.bit_buffer = bit_buffer
  self.bits_in = bits_in
}

///|
fn Sink::write_byte(self : Sink, b : Byte) -> Unit raise YaziError {
  match self.kind {
    SinkKind::Vec(out) => {
      out.push(b)
      self.pos = out.length()
    }
    SinkKind::Buf(buf) => {
      if self.pos >= buf.length() {
        raise YaziError::Overflow
      }
      buf[self.pos] = b
      self.pos = self.pos + 1
    }
  }
}

///|
fn Sink::pad(self : Sink) -> Unit raise YaziError {
  if self.bits_in != 0 {
    let len = 8 - self.bits_in
    self.put_bits(0, len)
  }
}

///|
fn Sink::put_bits(
  self : Sink,
  bits0 : UInt,
  len0 : Int,
) -> Unit raise YaziError {
  self.bit_buffer = self.bit_buffer | (bits0 << self.bits_in)
  self.bits_in = self.bits_in + len0
  while self.bits_in >= 8 {
    self.write_byte(byte_of_u(self.bit_buffer & 0xFF))
    self.bit_buffer = self.bit_buffer >> 8
    self.bits_in = self.bits_in - 8
  }
}

///|
/// A small batching helper used by CodeBuffer emission.
priv struct FastBits {
  mut bit_buffer : UInt64
  mut bits_in : Int
}

///|
fn FastBits::new(bit_buffer : UInt, bits_in : Int) -> FastBits {
  FastBits::{ bit_buffer: bit_buffer.to_uint64(), bits_in }
}

///|
fn FastBits::put(self : FastBits, bits : UInt, len : Int) -> Unit {
  self.bit_buffer = self.bit_buffer | (bits.to_uint64() << self.bits_in)
  self.bits_in = self.bits_in + len
}

///|
fn FastBits::flush(self : FastBits, sink : Sink) -> Unit raise YaziError {
  while self.bits_in >= 8 {
    sink.write_byte(byte_of_u((self.bit_buffer & 0xFF).to_uint()))
    self.bit_buffer = self.bit_buffer >> 8
    self.bits_in = self.bits_in - 8
  }
}
