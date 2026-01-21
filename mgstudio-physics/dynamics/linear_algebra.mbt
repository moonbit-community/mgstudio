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
struct RowDVector {
  data : Array[@core.Real]
  start : Int
  len : Int
}

///|
struct DVector {
  data : Array[@core.Real]
  start : Int
  len : Int
}

///|
fn RowDVector::new_view(
  data : Array[@core.Real],
  start : Int,
  len : Int,
) -> RowDVector {
  { data, start, len }
}

///|
fn DVector::new_view(
  data : Array[@core.Real],
  start : Int,
  len : Int,
) -> DVector {
  { data, start, len }
}

///|
fn RowDVector::value_at(self : RowDVector, index : Int) -> @core.Real {
  self.data[self.start + index]
}

///|
fn RowDVector::set_value(
  self : RowDVector,
  index : Int,
  value : @core.Real,
) -> Unit {
  self.data[self.start + index] = value
}

///|
fn DVector::value_at(self : DVector, index : Int) -> @core.Real {
  self.data[self.start + index]
}

///|
fn DVector::set_value(self : DVector, index : Int, value : @core.Real) -> Unit {
  self.data[self.start + index] = value
}

///|
pub fn RowDVector::from_fn(
  size : Int,
  init : (Int) -> @core.Real,
) -> RowDVector {
  let values : Array[@core.Real] = []
  for i in 0..<size {
    values.push(init(i))
  }
  RowDVector::new_view(values, 0, size)
}

///|
pub fn RowDVector::from_array(values : Array[@core.Real]) -> RowDVector {
  RowDVector::new_view(values, 0, values.length())
}

///|
pub fn DVector::from_fn(size : Int, init : (Int) -> @core.Real) -> DVector {
  let values : Array[@core.Real] = []
  for i in 0..<size {
    values.push(init(i))
  }
  DVector::new_view(values, 0, size)
}

///|
pub fn DVector::from_array(values : Array[@core.Real]) -> DVector {
  DVector::new_view(values, 0, values.length())
}

///|
pub fn RowDVector::equals(self : RowDVector, other : RowDVector) -> Bool {
  if self.len != other.len {
    return false
  }
  for i in 0..<self.len {
    if self.value_at(i) != other.value_at(i) {
      return false
    }
  }
  true
}

///|
pub fn DVector::equals(self : DVector, other : DVector) -> Bool {
  if self.len != other.len {
    return false
  }
  for i in 0..<self.len {
    if self.value_at(i) != other.value_at(i) {
      return false
    }
  }
  true
}

///|
pub fn RowDVector::len(self : RowDVector) -> Int {
  self.len
}

///|
pub fn DVector::len(self : DVector) -> Int {
  self.len
}

///|
pub fn RowDVector::scale(self : RowDVector, value : @core.Real) -> RowDVector {
  let values : Array[@core.Real] = []
  for i in 0..<self.len {
    values.push(self.value_at(i) * value)
  }
  RowDVector::new_view(values, 0, self.len)
}

///|
pub fn DVector::scale_in_place(self : DVector, value : @core.Real) -> Unit {
  for i in 0..<self.len {
    let current = self.value_at(i)
    self.set_value(i, current * value)
  }
}

///|
struct Jacobian {
  data : Array[@core.Real]
  mut cols : Int
}

///|
fn Jacobian::spatial_dim() -> Int {
  3
}

///|
pub fn Jacobian::zeros(size : Int) -> Jacobian {
  let total = Jacobian::spatial_dim() * size
  let data : Array[@core.Real] = []
  for _ in 0..<total {
    data.push(0.0F)
  }
  { data, cols: size }
}

///|
fn Jacobian::ensure_cols(self : Jacobian, cols : Int) -> Unit {
  if self.cols == cols {
    for i in 0..<self.data.length() {
      self.data[i] = 0.0F
    }
    return
  }
  self.cols = cols
  self.data.clear()
  let total = Jacobian::spatial_dim() * cols
  for _ in 0..<total {
    self.data.push(0.0F)
  }
}

///|
fn Jacobian::set_value(
  self : Jacobian,
  row : Int,
  col : Int,
  value : @core.Real,
) -> Unit {
  self.data[row * self.cols + col] = value
}

///|
pub fn Jacobian::equals(self : Jacobian, other : Jacobian) -> Bool {
  if self.cols != other.cols {
    return false
  }
  if self.data.length() != other.data.length() {
    return false
  }
  for i in 0..<self.data.length() {
    if self.data[i] != other.data[i] {
      return false
    }
  }
  true
}

///|
struct IndexSequence {
  mut first_to_remove : Int
  index_map : Array[Int]
}

///|
pub fn IndexSequence::new() -> IndexSequence {
  { first_to_remove: -1, index_map: [] }
}

///|
pub fn IndexSequence::remove(self : IndexSequence, index : Int) -> Unit {
  if self.first_to_remove < 0 {
    self.first_to_remove = index
  }
}

///|
pub fn IndexSequence::keep(self : IndexSequence, index : Int) -> Unit {
  if self.first_to_remove < 0 {
    return
  }
  self.index_map.push(index)
}

///|
fn IndexSequence::dim_after_removal(
  self : IndexSequence,
  original_dim : Int,
) -> Int {
  if self.first_to_remove < 0 {
    original_dim
  } else {
    self.first_to_remove + self.index_map.length()
  }
}

///|
pub fn IndexSequence::rearrange_columns(
  self : IndexSequence,
  vec : RowDVector,
  keep_columns : Bool,
) -> Unit {
  if self.first_to_remove < 0 {
    return
  }
  let base = self.first_to_remove
  let count = self.index_map.length()
  let mut shift = 0
  for source in self.index_map {
    let target = base + shift
    let value = vec.value_at(source)
    vec.set_value(target, value)
    shift = shift + 1
  }
  if keep_columns {
    for i in (base + count)..<vec.len() {
      vec.set_value(i, 0.0F)
    }
  }
}

///|
pub fn IndexSequence::rearrange_rows(
  self : IndexSequence,
  vec : DVector,
  keep_rows : Bool,
) -> Unit {
  if self.first_to_remove < 0 {
    return
  }
  let base = self.first_to_remove
  let count = self.index_map.length()
  let mut shift = 0
  for source in self.index_map {
    let target = base + shift
    let value = vec.value_at(source)
    vec.set_value(target, value)
    shift = shift + 1
  }
  if keep_rows {
    for i in (base + count)..<vec.len() {
      vec.set_value(i, 0.0F)
    }
  }
}

///|
pub fn IndexSequence::inv_rearrange_rows(
  self : IndexSequence,
  vec : DVector,
) -> Unit {
  if self.first_to_remove < 0 {
    return
  }
  let count = self.index_map.length()
  for i in 0..<count {
    let rev_index = count - 1 - i
    let source = self.index_map[rev_index]
    let target = self.first_to_remove + rev_index
    let value = vec.value_at(target)
    vec.set_value(source, value)
    vec.set_value(target, 0.0F)
  }
}

///|
pub fn IndexSequence::with_rearranged_rows_mut(
  self : IndexSequence,
  vec : DVector,
  action : (DVector) -> Unit,
) -> Unit {
  self.rearrange_rows(vec, true)
  let effective_dim = self.dim_after_removal(vec.len())
  if effective_dim > 0 {
    let view = DVector::new_view(vec.data, vec.start, effective_dim)
    action(view)
  }
  self.inv_rearrange_rows(vec)
}
