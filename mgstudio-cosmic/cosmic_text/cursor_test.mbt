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

test "Affinity helpers" {
  inspect(Affinity::Before.before(), content="true")
  inspect(Affinity::Before.after(), content="false")
  inspect(Affinity::After.before(), content="false")
  inspect(Affinity::After.after(), content="true")
  inspect(match Affinity::from_before(true) { Before => true; _ => false }, content="true")
  inspect(match Affinity::from_after(true) { After => true; _ => false }, content="true")
}

test "Cursor constructors" {
  let c0 = Cursor::new(1, 2)
  inspect(c0.line, content="1")
  inspect(c0.index, content="2")
  inspect(match c0.affinity { Before => true; _ => false }, content="true")
  let c1 = Cursor::new_with_affinity(3, 4, Affinity::After)
  inspect(match c1.affinity { After => true; _ => false }, content="true")
}

test "Scroll default/new" {
  let s0 = Scroll::default()
  inspect(s0.line, content="0")
  inspect(s0.vertical, content="0")
  inspect(s0.horizontal, content="0")
  let s1 = Scroll::new(2, 3.0F, 4.0F)
  inspect(s1.line, content="2")
  inspect(s1.vertical, content="3")
  inspect(s1.horizontal, content="4")
}
