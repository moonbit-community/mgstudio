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
test "color owns Color constructors" {
  let white = @color.Color::white()
  let black = @color.Color::black()
  inspect(white.r.to_double(), content="1")
  inspect(white.g.to_double(), content="1")
  inspect(white.b.to_double(), content="1")
  inspect(white.a.to_double(), content="1")
  inspect(black.r.to_double(), content="0")
  inspect(black.g.to_double(), content="0")
  inspect(black.b.to_double(), content="0")
  inspect(black.a.to_double(), content="1")
}

///|
test "color exposes alpha channel" {
  let color = @color.Color::new(0.2F, 0.4F, 0.6F, 0.25F)
  inspect(color.alpha().to_double(), content="0.25")
}
