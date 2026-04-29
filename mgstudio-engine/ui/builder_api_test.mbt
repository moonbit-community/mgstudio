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
  debug_inspect(node.column_gap == Val::Px(15.0F), content="true")
}

///|
test "ui: node default includes Bevy-owned box and radius fields" {
  let node = Node::default()
  debug_inspect(node.box_sizing == BoxSizing::BorderBox, content="true")
  debug_inspect(node.scrollbar_width == 0.0F, content="true")
  debug_inspect(node.border_radius.top_left == Val::Px(0.0F), content="true")
  debug_inspect(node.border_radius.top_right == Val::Px(0.0F), content="true")
  debug_inspect(
    node.border_radius.bottom_right == Val::Px(0.0F),
    content="true",
  )
  debug_inspect(node.border_radius.bottom_left == Val::Px(0.0F), content="true")
}

///|
test "ui: node builders update Bevy-owned box and radius fields" {
  let radius = BorderRadius::all(Val::Px(6.0F))
  let node = Node::default()
    .with_box_sizing(BoxSizing::ContentBox)
    .with_scrollbar_width(12.0F)
    .with_border_radius(radius)
  debug_inspect(node.box_sizing == BoxSizing::ContentBox, content="true")
  debug_inspect(node.scrollbar_width == 12.0F, content="true")
  debug_inspect(node.border_radius.top_left == radius.top_left, content="true")
  debug_inspect(
    node.border_radius.top_right == radius.top_right,
    content="true",
  )
  debug_inspect(
    node.border_radius.bottom_right == radius.bottom_right,
    content="true",
  )
  debug_inspect(
    node.border_radius.bottom_left == radius.bottom_left,
    content="true",
  )
}

///|
test "ui: atlas image builder keeps image and atlas together" {
  let image = @asset.Handle::new(7)
  let texture_atlas = @asset.TextureAtlas::new(@asset.Handle::new(9), 3)
  let image_node = ImageNode::from_atlas_image(image, texture_atlas)
  debug_inspect(image_node.image.id() == image.id(), content="true")
  let has_matching_atlas = match image_node.texture_atlas {
    Some(atlas) => atlas.index == 3 && atlas.layout.id() == 9
    None => false
  }
  debug_inspect(has_matching_atlas, content="true")
}
