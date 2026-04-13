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
test "utils boundary exports default helper and type-id helpers" {
  let value = @any.Any::of(7)
  let zero : Int = @utils.default()
  debug_inspect(zero, content="0")
  debug_inspect(@utils.type_name(value), content="\"Int\"")
}

///|
test "utils once: OnceFlag and OnceCell behave like one-shot helpers" {
  let flag = @utils.OnceFlag::new()
  debug_inspect(flag.set(), content="true")
  debug_inspect(flag.set(), content="false")

  let cell = @utils.OnceCell::new()
  debug_inspect(cell.set_once(7), content="true")
  debug_inspect(cell.set_once(9), content="false")
  debug_inspect(cell.get(), content="Some(7)")
  debug_inspect(cell.get_or_init(fn() { 11 }), content="7")
}

///|
test "utils atomic_id: generated ids are positive and monotonic" {
  let a = @utils.atomic_id_next()
  let b = @utils.atomic_id_next()
  debug_inspect(a > 0, content="true")
  debug_inspect(b > a, content="true")
}
