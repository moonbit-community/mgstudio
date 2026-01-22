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

test "Color rgb/rgba packing" {
  let c0 = Color::rgb(1, 2, 3)
  inspect(c0.r().to_int(), content="1")
  inspect(c0.g().to_int(), content="2")
  inspect(c0.b().to_int(), content="3")
  inspect(c0.a().to_int(), content="255")

  let c1 = Color::rgba(9, 8, 7, 6)
  inspect(c1.as_rgba().0.to_int(), content="9")
  inspect(c1.as_rgba().1.to_int(), content="8")
  inspect(c1.as_rgba().2.to_int(), content="7")
  inspect(c1.as_rgba().3.to_int(), content="6")
}

