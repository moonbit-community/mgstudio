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
pub let ecs_components : Array[String] = [
  "Node", "Label", "Button", "UiRoot", "IsDefaultUiCamera", "UiTargetCamera", "ComputedUiTargetCamera",
  "ComputedUiRenderTargetInfo", "ZIndex", "Outline", "UiImage", "UiLayout", "BoxShadow",
  "ImageNode", "BorderColor", "ContentSize", "FocusPolicy", "Interaction", "BorderRadius",
  "ButtonColors", "GlobalZIndex", "ImageNodeSize", "CalculatedClip", "ScrollPosition",
  "BackgroundColor", "AccessibilityLabel", "RelativeCursorPosition",
]

///|
pub let ecs_resources : Array[String] = ["UiScale", "UiStack", "UiContext"]

///|
pub fn get_ui_scale_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[UiScale] {
  world.resource(ecs_key_ui_scale)
}

///|
pub fn get_ui_stack_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[UiStack] {
  world.resource(ecs_key_ui_stack)
}

///|
pub fn get_ui_context_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[UiContext] {
  world.resource(ecs_key_ui_context)
}
