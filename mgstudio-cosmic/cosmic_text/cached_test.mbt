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

test "Cached: state machine semantics" {
  let c0 : Cached[Int] = Empty
  inspect(c0.is_unused(), content="true")
  inspect(c0.is_used(), content="false")
  inspect(c0.get(), content="None")

  let c1 = c0.set_used(123)
  inspect(c1.is_used(), content="true")
  inspect(c1.get(), content="Some(123)")

  let c2 = c1.set_unused()
  inspect(c2.is_unused(), content="true")
  inspect(c2.get(), content="None")

  let (c3, v3) = c2.take_unused()
  inspect(match c3 { Empty => true; _ => false }, content="true")
  inspect(v3, content="Some(123)")
}
