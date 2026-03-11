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
test "ui: node builder stores explicit column gap" {
  let node = Node::default().with_column_gap(Val::Px(15.0F))
  inspect(node.column_gap == Val::Px(15.0F), content="true")
}

///|
test "ui: atlas image builder keeps image and atlas together" {
  let image = @asset.Handle::new(7)
  let texture_atlas = @asset.TextureAtlas::new(@asset.Handle::new(9), 3)
  let image_node = ImageNode::from_atlas_image(image, texture_atlas)
  inspect(image_node.image.id() == image.id(), content="true")
  let has_matching_atlas = match image_node.texture_atlas {
    Some(atlas) => atlas.index == 3 && atlas.layout.id() == 9
    None => false
  }
  inspect(has_matching_atlas, content="true")
}
