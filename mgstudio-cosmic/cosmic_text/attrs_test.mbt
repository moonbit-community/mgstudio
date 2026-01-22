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

test "AttrsList: add_span/get_span" {
  let defaults = Attrs::new()
  let list0 = AttrsList::new(defaults)
  inspect(list0.get_span(0).metadata(), content="0")

  let list1 = list0.add_span(0, 2, Attrs::with_metadata(7))
  inspect(list1.get_span(0).metadata(), content="7")
  inspect(list1.get_span(1).metadata(), content="7")
  inspect(list1.get_span(2).metadata(), content="0")
}

test "AttrsList: split_off shifts right spans" {
  let defaults = Attrs::new()
  let list0 = AttrsList::new(defaults)
    .add_span(1, 4, Attrs::with_metadata(1))
    .add_span(5, 7, Attrs::with_metadata(2))

  let (left, right) = list0.split_off(3)

  // left keeps [1,3)
  inspect(left.get_span(2).metadata(), content="1")
  inspect(left.get_span(3).metadata(), content="0")

  // right gets shifted: original [5,7) becomes [2,4)
  inspect(right.get_span(1).metadata(), content="0")
  inspect(right.get_span(2).metadata(), content="2")
  inspect(right.get_span(3).metadata(), content="2")
  inspect(right.get_span(4).metadata(), content="0")
}
