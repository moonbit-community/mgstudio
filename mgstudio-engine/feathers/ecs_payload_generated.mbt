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
extenum @ecs.EcsPayload += {
  EcsPayload_feathers_UiTheme(UiTheme)
  EcsPayload_feathers_ThemeBackgroundColor(ThemeBackgroundColor)
  EcsPayload_feathers_ThemeBorderColor(ThemeBorderColor)
  EcsPayload_feathers_ThemeFontColor(ThemeFontColor)
  EcsPayload_feathers_ThemedText(ThemedText)
  EcsPayload_feathers_AlphaPatternResource(AlphaPatternResource)
  EcsPayload_feathers_AlphaPatternPluginMarker(AlphaPatternPluginMarker)
  EcsPayload_feathers_DefaultCursor(DefaultCursor)
  EcsPayload_feathers_CursorIconPluginMarker(CursorIconPluginMarker)
  EcsPayload_feathers_FeathersPluginMarker(FeathersPluginMarker)
  EcsPayload_feathers_InheritableFont(InheritableFont)
}

///|
pub impl @ecs.EcsPayloadCodec for UiTheme with to_ecs_payload(self) {
  EcsPayload_feathers_UiTheme(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UiTheme with from_ecs_payload(payload) {
  match payload {
    EcsPayload_feathers_UiTheme(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ThemeBackgroundColor with to_ecs_payload(self) {
  EcsPayload_feathers_ThemeBackgroundColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ThemeBackgroundColor with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_feathers_ThemeBackgroundColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ThemeBorderColor with to_ecs_payload(self) {
  EcsPayload_feathers_ThemeBorderColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ThemeBorderColor with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_feathers_ThemeBorderColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ThemeFontColor with to_ecs_payload(self) {
  EcsPayload_feathers_ThemeFontColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ThemeFontColor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_feathers_ThemeFontColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ThemedText with to_ecs_payload(self) {
  EcsPayload_feathers_ThemedText(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ThemedText with from_ecs_payload(payload) {
  match payload {
    EcsPayload_feathers_ThemedText(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AlphaPatternResource with to_ecs_payload(self) {
  EcsPayload_feathers_AlphaPatternResource(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AlphaPatternResource with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_feathers_AlphaPatternResource(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AlphaPatternPluginMarker with to_ecs_payload(
  self,
) {
  EcsPayload_feathers_AlphaPatternPluginMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AlphaPatternPluginMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_feathers_AlphaPatternPluginMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DefaultCursor with to_ecs_payload(self) {
  EcsPayload_feathers_DefaultCursor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DefaultCursor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_feathers_DefaultCursor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CursorIconPluginMarker with to_ecs_payload(
  self,
) {
  EcsPayload_feathers_CursorIconPluginMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CursorIconPluginMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_feathers_CursorIconPluginMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FeathersPluginMarker with to_ecs_payload(self) {
  EcsPayload_feathers_FeathersPluginMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FeathersPluginMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_feathers_FeathersPluginMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for InheritableFont with to_ecs_payload(self) {
  EcsPayload_feathers_InheritableFont(self)
}

///|
pub impl @ecs.EcsPayloadCodec for InheritableFont with from_ecs_payload(payload) {
  match payload {
    EcsPayload_feathers_InheritableFont(value) => Some(value)
    _ => None
  }
}
