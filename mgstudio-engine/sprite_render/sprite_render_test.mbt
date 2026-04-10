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
test "sprite_render boundary re-exports wireframe config and alpha mode" {
  let config = @sprite_render.Wireframe2dConfig::default()
  debug_inspect(config.global, content="false")
  debug_inspect(config.default_color.r.to_double(), content="1")
  debug_inspect(
    @sprite_render.AlphaMode2d::Blend.to_json().to_string(),
    content="String(\"Blend\")",
  )
}

///|
test "sprite_render boundary re-exports render schedule labels" {
  debug_inspect(
    @sprite_render.render2d_set_extract == @sprite.render2d_set_extract,
    content="true",
  )
  debug_inspect(
    @sprite_render.render2d_set_render == @sprite.render2d_set_render,
    content="true",
  )
}
