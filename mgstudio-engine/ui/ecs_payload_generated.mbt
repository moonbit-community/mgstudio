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
  EcsPayload_ui_AutoDirectionalNavigation(AutoDirectionalNavigation)
  EcsPayload_ui_Node(Node)
  EcsPayload_ui_Label(Label)
  EcsPayload_ui_Button(Button)
  EcsPayload_ui_UiRoot(UiRoot)
  EcsPayload_ui_GhostNode(GhostNode)
  EcsPayload_ui_IsDefaultUiCamera(IsDefaultUiCamera)
  EcsPayload_ui_UiTargetCamera(UiTargetCamera)
  EcsPayload_ui_ComputedUiTargetCamera(ComputedUiTargetCamera)
  EcsPayload_ui_ComputedUiRenderTargetInfo(ComputedUiRenderTargetInfo)
  EcsPayload_ui_ZIndex(ZIndex)
  EcsPayload_ui_Outline(Outline)
  EcsPayload_ui_UiImage(UiImage)
  EcsPayload_ui_UiLayout(UiLayout)
  EcsPayload_ui_BoxShadow(BoxShadow)
  EcsPayload_ui_ImageNode(ImageNode)
  EcsPayload_ui_BorderColor(BorderColor)
  EcsPayload_ui_ContentSize(ContentSize)
  EcsPayload_ui_FocusPolicy(FocusPolicy)
  EcsPayload_ui_Interaction(Interaction)
  EcsPayload_ui_ButtonColors(ButtonColors)
  EcsPayload_ui_GlobalZIndex(GlobalZIndex)
  EcsPayload_ui_ImageNodeSize(ImageNodeSize)
  EcsPayload_ui_CalculatedClip(CalculatedClip)
  EcsPayload_ui_ScrollPosition(ScrollPosition)
  EcsPayload_ui_BackgroundColor(BackgroundColor)
  EcsPayload_ui_AccessibilityLabel(AccessibilityLabel)
  EcsPayload_ui_RelativeCursorPosition(RelativeCursorPosition)
  EcsPayload_ui_InteractionDisabled(InteractionDisabled)
  EcsPayload_ui_Pressed(Pressed)
  EcsPayload_ui_Checkable(Checkable)
  EcsPayload_ui_Checked(Checked)
  EcsPayload_ui_UiScale(UiScale)
  EcsPayload_ui_UiStack(UiStack)
  EcsPayload_ui_UiContext(UiContext)
}

///|
pub impl @ecs.EcsPayloadCodec for AutoDirectionalNavigation with to_ecs_payload(
  self,
) {
  EcsPayload_ui_AutoDirectionalNavigation(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AutoDirectionalNavigation with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_AutoDirectionalNavigation(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Node with to_ecs_payload(self) {
  EcsPayload_ui_Node(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Node with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_Node(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Label with to_ecs_payload(self) {
  EcsPayload_ui_Label(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Label with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_Label(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Button with to_ecs_payload(self) {
  EcsPayload_ui_Button(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Button with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_Button(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for UiRoot with to_ecs_payload(self) {
  EcsPayload_ui_UiRoot(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UiRoot with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_UiRoot(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GhostNode with to_ecs_payload(self) {
  EcsPayload_ui_GhostNode(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GhostNode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_GhostNode(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for IsDefaultUiCamera with to_ecs_payload(self) {
  EcsPayload_ui_IsDefaultUiCamera(self)
}

///|
pub impl @ecs.EcsPayloadCodec for IsDefaultUiCamera with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_IsDefaultUiCamera(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for UiTargetCamera with to_ecs_payload(self) {
  EcsPayload_ui_UiTargetCamera(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UiTargetCamera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_UiTargetCamera(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ComputedUiTargetCamera with to_ecs_payload(
  self,
) {
  EcsPayload_ui_ComputedUiTargetCamera(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ComputedUiTargetCamera with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_ComputedUiTargetCamera(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ComputedUiRenderTargetInfo with to_ecs_payload(
  self,
) {
  EcsPayload_ui_ComputedUiRenderTargetInfo(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ComputedUiRenderTargetInfo with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_ComputedUiRenderTargetInfo(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ZIndex with to_ecs_payload(self) {
  EcsPayload_ui_ZIndex(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ZIndex with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_ZIndex(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Outline with to_ecs_payload(self) {
  EcsPayload_ui_Outline(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Outline with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_Outline(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for UiImage with to_ecs_payload(self) {
  EcsPayload_ui_UiImage(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UiImage with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_UiImage(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for UiLayout with to_ecs_payload(self) {
  EcsPayload_ui_UiLayout(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UiLayout with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_UiLayout(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BoxShadow with to_ecs_payload(self) {
  EcsPayload_ui_BoxShadow(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BoxShadow with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_BoxShadow(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ImageNode with to_ecs_payload(self) {
  EcsPayload_ui_ImageNode(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ImageNode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_ImageNode(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BorderColor with to_ecs_payload(self) {
  EcsPayload_ui_BorderColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BorderColor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_BorderColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ContentSize with to_ecs_payload(self) {
  EcsPayload_ui_ContentSize(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ContentSize with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_ContentSize(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FocusPolicy with to_ecs_payload(self) {
  EcsPayload_ui_FocusPolicy(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FocusPolicy with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_FocusPolicy(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Interaction with to_ecs_payload(self) {
  EcsPayload_ui_Interaction(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Interaction with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_Interaction(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ButtonColors with to_ecs_payload(self) {
  EcsPayload_ui_ButtonColors(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ButtonColors with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_ButtonColors(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalZIndex with to_ecs_payload(self) {
  EcsPayload_ui_GlobalZIndex(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalZIndex with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_GlobalZIndex(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ImageNodeSize with to_ecs_payload(self) {
  EcsPayload_ui_ImageNodeSize(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ImageNodeSize with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_ImageNodeSize(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CalculatedClip with to_ecs_payload(self) {
  EcsPayload_ui_CalculatedClip(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CalculatedClip with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_CalculatedClip(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ScrollPosition with to_ecs_payload(self) {
  EcsPayload_ui_ScrollPosition(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ScrollPosition with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_ScrollPosition(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for BackgroundColor with to_ecs_payload(self) {
  EcsPayload_ui_BackgroundColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for BackgroundColor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_BackgroundColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AccessibilityLabel with to_ecs_payload(self) {
  EcsPayload_ui_AccessibilityLabel(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AccessibilityLabel with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_AccessibilityLabel(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RelativeCursorPosition with to_ecs_payload(
  self,
) {
  EcsPayload_ui_RelativeCursorPosition(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RelativeCursorPosition with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_RelativeCursorPosition(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for InteractionDisabled with to_ecs_payload(self) {
  EcsPayload_ui_InteractionDisabled(self)
}

///|
pub impl @ecs.EcsPayloadCodec for InteractionDisabled with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_InteractionDisabled(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Pressed with to_ecs_payload(self) {
  EcsPayload_ui_Pressed(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Pressed with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_Pressed(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Checkable with to_ecs_payload(self) {
  EcsPayload_ui_Checkable(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Checkable with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_Checkable(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Checked with to_ecs_payload(self) {
  EcsPayload_ui_Checked(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Checked with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_Checked(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for UiScale with to_ecs_payload(self) {
  EcsPayload_ui_UiScale(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UiScale with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_UiScale(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for UiStack with to_ecs_payload(self) {
  EcsPayload_ui_UiStack(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UiStack with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_UiStack(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for UiContext with to_ecs_payload(self) {
  EcsPayload_ui_UiContext(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UiContext with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_UiContext(value) => Some(value)
    _ => None
  }
}
