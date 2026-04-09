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
// Bevy source: `bevy/crates/bevy_ui/src/widget/image.rs`.
// Bridge surface to the root `ui` package implementation.
pub using @ui {type BorderRect}

///|
pub using @ui {type ImageNode}

///|
pub using @ui {type ImageNodeSize}

///|
pub using @ui {type NodeImageMode}

///|
pub using @ui {type SliceScaleMode}

///|
pub using @ui {type TextureSlicer}

///|
pub using @ui {type UiImage}

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_image_node : @ecs.ComponentKey[@ui.ImageNode] = @ui.ecs_key_image_node

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_image_node_size : @ecs.ComponentKey[@ui.ImageNodeSize] = @ui.ecs_key_image_node_size

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_ui_image : @ecs.ComponentKey[@ui.UiImage] = @ui.ecs_key_ui_image
