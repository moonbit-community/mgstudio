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
// Bevy source: `bevy/crates/bevy_asset/src/processor/process.rs`.
pub using @asset {type ProcessedAsset}

///|
pub fn[T] init_asset_processor(
  app : @app.App[@ecs.World],
  processor : LoadTransformAndSave[T],
) -> @app.App[@ecs.World] {
  @asset.init_asset_processor(app, processor)
}

///|
pub fn[T] register_asset_processor(
  app : @app.App[@ecs.World],
  processor : LoadTransformAndSave[T],
) -> @app.App[@ecs.World] {
  @asset.register_asset_processor(app, processor)
}

///|
pub fn[T] asset_processor_extensions(
  processor : LoadTransformAndSave[T],
) -> Array[String] {
  processor.extensions
}

///|
pub fn[T] asset_processor_process(
  processor : LoadTransformAndSave[T],
  asset_server : @asset.AssetServer,
  path : @asset.AssetPath,
  bytes : Bytes,
) -> ProcessedAsset[T] raise @asset.AssetProcessError {
  (processor.process)(asset_server, path, bytes)
}
