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
// Bevy source: `bevy/crates/bevy_asset/src/io/embedded/mod.rs`.
pub fn[P : IntoAssetPath] embedded_asset(
  app : @app.App[@ecs.World],
  asset_path : P,
  source_path : String,
) -> @app.App[@ecs.World] {
  let virtual_path = asset_format_path(asset_path.into_asset_path())
  let mut resolved_source_path = source_path
  let bytes = try @fs.read_file_to_bytes(source_path) catch {
    _ => {
      let source_is_absolute = source_path.length() > 0 &&
        source_path.code_unit_at(0) == 47
      if source_is_absolute {
        abort(
          "embedded_asset: failed to read source path `\{source_path}` for `\{virtual_path}`",
        )
      }
      let fallback = "mgstudio-engine/\{source_path}"
      try @fs.read_file_to_bytes(fallback) catch {
        _ =>
          abort(
            "embedded_asset: failed to read source path `\{source_path}` (and fallback `\{fallback}`) for `\{virtual_path}`",
          )
      } noraise {
        value => {
          resolved_source_path = fallback
          value
        }
      }
    }
  } noraise {
    value => value
  }
  register_embedded_asset_virtual_bytes(virtual_path, bytes)
  ignore(resolved_source_path)
  app
}
