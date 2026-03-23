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
fn asset_saving_test_app() -> @app.App[@ecs.World] {
  asset_saving_plugin(
    @app.App::new(@ecs.World::new()).add_plugin_group(fn() {
      @mgstudio.DefaultPlugins::set(
        @asset.AssetPlugin::default().with_file_path(
          ".private/test_artifacts/asset_saving_roundtrip",
        ),
      )
    }),
  )
}

///|
test "asset_saving roundtrip recreates labeled OneBox subassets" {
  let app = asset_saving_test_app()
  let world = app.world()
  let asset_server = match
    (try! world.get_resource(@asset.asset_server_resource_key())) {
    Some(server) => server
    None => abort("expected AssetServer resource in asset_saving test app")
  }

  let expected_boxes = [
    OneBox::{
      position: @math.Vec2::new(10.0F, 20.0F),
      color: @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
    },
    OneBox::{
      position: @math.Vec2::new(-30.0F, 15.0F),
      color: @sprite.Color::new(0.0F, 0.25F, 1.0F, 1.0F),
    },
  ]

  @asset.asset_with_world(world, fn() {
    let builder = @asset.SavedAssetBuilder::new(
      asset_server,
      @asset.AssetPath::from_path("roundtrip.boxes"),
    )
    let many_boxes = ManyBoxes::{ boxes: [] }
    for i in 0..<expected_boxes.length() {
      many_boxes.boxes.push(
        builder.add_labeled_asset_with_new_handle(
          i.to_string(),
          @asset.SavedAsset::from_asset(expected_boxes[i]),
        ),
      )
    }
    match
      @asset.save_using_saver(
        asset_server,
        many_boxes_saver(),
        @asset.AssetPath::from_path("roundtrip.boxes"),
        builder.build(many_boxes),
        (),
      ) {
      Ok(_) => ()
      Err(err) => abort("expected asset save to succeed, got " + err)
    }
  })

  let handle : @asset.Handle[ManyBoxes] = @asset.asset_with_world(world, fn() {
    asset_server.load("roundtrip.boxes")
  })
  @asset.asset_with_world(world, fn() { @asset.asset_system(world) })

  let many_boxes_assets_key : @ecs.ResourceKey[@asset.Assets[ManyBoxes]] = @asset.assets_resource_key()
  let one_box_assets_key : @ecs.ResourceKey[@asset.Assets[OneBox]] = @asset.assets_resource_key()
  let many_boxes_assets = match
    (try! world.get_resource(many_boxes_assets_key)) {
    Some(assets) => assets
    None => abort("expected Assets<ManyBoxes> resource")
  }
  let one_box_assets = match (try! world.get_resource(one_box_assets_key)) {
    Some(assets) => assets
    None => abort("expected Assets<OneBox> resource")
  }
  let loaded = match many_boxes_assets.get(handle) {
    Some(asset) => asset
    None => abort("expected saved ManyBoxes asset to load")
  }

  inspect(loaded.boxes.length(), content="2")
  inspect(
    match one_box_assets.get(loaded.boxes[0]) {
      Some(one_box) =>
        one_box.position.x == 10.0F &&
        one_box.position.y == 20.0F &&
        one_box.color.r == 1.0F &&
        one_box.color.g == 0.0F &&
        one_box.color.b == 0.0F &&
        one_box.color.a == 1.0F
      None => false
    },
    content="true",
  )
  inspect(
    match one_box_assets.get(loaded.boxes[1]) {
      Some(one_box) =>
        one_box.position.x == -30.0F &&
        one_box.position.y == 15.0F &&
        one_box.color.r == 0.0F &&
        one_box.color.g == 0.25F &&
        one_box.color.b == 1.0F &&
        one_box.color.a == 1.0F
      None => false
    },
    content="true",
  )
}
