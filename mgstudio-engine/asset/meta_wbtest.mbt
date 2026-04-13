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
fn meta_layout_is_row_count(layout : ImageArrayLayout?, rows : Int) -> Bool {
  match layout {
    Some(ImageArrayLayout::RowCount(actual)) => actual == rows
    _ => false
  }
}

///|
fn meta_layout_is_row_height(layout : ImageArrayLayout?, pixels : Int) -> Bool {
  match layout {
    Some(ImageArrayLayout::RowHeight(actual)) => actual == pixels
    _ => false
  }
}

///|
test "asset wb: image meta applies format/texture/usages and row-height layout" {
  let settings = ImageLoaderSettings::default()
  let content = "(asset: Load(settings: (format: Guess, texture_format: Some(Rgba16Float), is_srgb: false, array_layout: Some(RowHeight { pixels: 64 }), asset_usage: RenderAssetUsages(\"RENDER_WORLD\"), load_meshes: RenderAssetUsages(\"MAIN_WORLD\"),),),)"
  apply_image_meta_settings(settings, content)
  debug_inspect(settings.format == ImageFormatSetting::Guess, content="true")
  debug_inspect(settings.texture_format == Some(TextureFormat::Rgba16Float), content="true")
  debug_inspect(!settings.is_srgb, content="true")
  debug_inspect(
    settings.asset_usage == RenderAssetUsages::render_world(),
    content="true",
  )
  debug_inspect(
    settings.load_meshes == RenderAssetUsages::main_world(),
    content="true",
  )
  debug_inspect(meta_layout_is_row_height(settings.array_layout, 64), content="true")
}

///|
test "asset wb: image meta accepts row-count and explicit format variant" {
  let settings = ImageLoaderSettings::default()
  let content = "(asset: Load(settings: (format: Format(Png), array_layout: Some(RowCount(rows: 4)), asset_usage: RenderAssetUsages(\"MAIN_WORLD | RENDER_WORLD\"), load_meshes: RenderAssetUsages(\"RENDER_WORLD | MAIN_WORLD\"),),),)"
  apply_image_meta_settings(settings, content)
  debug_inspect(
    settings.format == ImageFormatSetting::Format(ImageContainerFormat::Png),
    content="true",
  )
  debug_inspect(meta_layout_is_row_count(settings.array_layout, 4), content="true")
  debug_inspect(settings.asset_usage == RenderAssetUsages::all(), content="true")
  debug_inspect(settings.load_meshes == RenderAssetUsages::all(), content="true")
}
