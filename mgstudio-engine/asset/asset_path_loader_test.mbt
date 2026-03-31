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
test "asset path parse supports source and label" {
  let parsed_default = asset_parse_path("textures/ui.png#atlas0")
  inspect(parsed_default.path, content="textures/ui.png")
  inspect(parsed_default.label is Some("atlas0"), content="true")
  inspect(parsed_default.source is AssetSourceId::Default, content="true")

  let parsed_named = asset_parse_path("remote://models/scene.gltf#Scene0")
  inspect(parsed_named.path, content="models/scene.gltf")
  inspect(parsed_named.label is Some("Scene0"), content="true")
  inspect(parsed_named.source is AssetSourceId::Named("remote"), content="true")

  inspect(
    asset_strip_label("remote://models/scene.gltf#Scene0"),
    content="remote://models/scene.gltf",
  )
}

///|
test "asset path try_parse follows Bevy syntax checks" {
  let mut missing_source_error : ParseAssetPathError? = None
  ignore(asset_try_parse_path("://file.test")) catch {
    err => missing_source_error = Some(err)
  }
  inspect(
    missing_source_error is Some(ParseAssetPathError::MissingSource),
    content="true",
  )

  let mut missing_label_error : ParseAssetPathError? = None
  ignore(asset_try_parse_path("source://file.test#")) catch {
    err => missing_label_error = Some(err)
  }
  inspect(
    missing_label_error is Some(ParseAssetPathError::MissingLabel),
    content="true",
  )

  let mut invalid_source_syntax_error : ParseAssetPathError? = None
  ignore(asset_try_parse_path("bad#source://file.test")) catch {
    err => invalid_source_syntax_error = Some(err)
  }
  inspect(
    invalid_source_syntax_error
    is Some(ParseAssetPathError::InvalidSourceSyntax),
    content="true",
  )

  let mut invalid_label_syntax_error : ParseAssetPathError? = None
  ignore(asset_try_parse_path("source://file.test#bad://label")) catch {
    err => invalid_label_syntax_error = Some(err)
  }
  inspect(
    invalid_label_syntax_error is Some(ParseAssetPathError::InvalidLabelSyntax),
    content="true",
  )
}

///|
test "asset loader registry supports extension override" {
  inspect(
    asset_loader_kind_for_path("textures/a.png") is AssetLoaderKind::Texture,
    content="true",
  )

  asset_remove_loader_extension("customx")
  inspect(
    asset_loader_kind_for_path("foo.customx") is AssetLoaderKind::Bytes,
    content="true",
  )

  asset_register_loader_extension("customx", AssetLoaderKind::Wgsl)
  inspect(
    asset_loader_kind_for_path("foo.customx") is AssetLoaderKind::Wgsl,
    content="true",
  )

  asset_remove_loader_extension("customx")
  inspect(
    asset_loader_kind_for_path("foo.customx") is AssetLoaderKind::Bytes,
    content="true",
  )
}
