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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/atomic_pod.rs`.

///|
pub struct AtomicPodBlob {
  words : Array[UInt]
} derive(Eq, Debug)

///|
pub fn AtomicPodBlob::new(word_count : Int) -> AtomicPodBlob {
  if word_count < 0 {
    abort("atomic pod word count must be non-negative")
  }
  AtomicPodBlob::{ words: Array::make(word_count, 0U) }
}

///|
pub fn AtomicPodBlob::from_words(words : Array[UInt]) -> AtomicPodBlob {
  AtomicPodBlob::{ words: words.copy() }
}

///|
pub fn AtomicPodBlob::word_count(self : AtomicPodBlob) -> Int {
  self.words.length()
}

///|
pub fn AtomicPodBlob::read_word(self : AtomicPodBlob, index : Int) -> UInt {
  self.words[index]
}

///|
pub fn AtomicPodBlob::write_word(
  self : AtomicPodBlob,
  index : Int,
  value : UInt,
) -> Unit {
  self.words[index] = value
}

///|
pub fn AtomicPodBlob::read_words(self : AtomicPodBlob) -> Array[UInt] {
  self.words.copy()
}

///|
pub fn AtomicPodBlob::write_words(
  self : AtomicPodBlob,
  values : Array[UInt],
) -> Unit {
  if values.length() != self.words.length() {
    abort("atomic pod blob word length mismatch")
  }
  for i in 0..<values.length() {
    self.words[i] = values[i]
  }
}

///|
pub fn AtomicPodBlob::field_words(
  self : AtomicPodBlob,
  word_offset : Int,
  word_count : Int,
) -> Array[UInt] {
  if word_offset < 0 ||
    word_count < 0 ||
    word_offset + word_count > self.words.length() {
    abort("atomic pod field word range out of bounds")
  }
  let out : Array[UInt] = []
  for i in word_offset..<(word_offset + word_count) {
    out.push(self.words[i])
  }
  out
}

///|
pub fn AtomicPodBlob::set_field_words(
  self : AtomicPodBlob,
  word_offset : Int,
  values : Array[UInt],
) -> Unit {
  if word_offset < 0 || word_offset + values.length() > self.words.length() {
    abort("atomic pod field word range out of bounds")
  }
  for i in 0..<values.length() {
    self.words[word_offset + i] = values[i]
  }
}

///|
pub fn atomic_pod_word_count(byte_size : Int) -> Int {
  if byte_size < 0 || byte_size % 4 != 0 {
    abort("atomic pod byte size must be a non-negative multiple of 4")
  }
  byte_size / 4
}

///|
pub fn atomic_pod_unit_blob() -> AtomicPodBlob {
  AtomicPodBlob::new(0)
}
