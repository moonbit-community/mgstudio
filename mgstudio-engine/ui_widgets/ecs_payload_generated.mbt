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
  EcsPayload_ui_widgets_InteractionDisabled(InteractionDisabled)
  EcsPayload_ui_widgets_Pressed(Pressed)
  EcsPayload_ui_widgets_Checkable(Checkable)
  EcsPayload_ui_widgets_Checked(Checked)
  EcsPayload_ui_widgets_RadioGroup(RadioGroup)
  EcsPayload_ui_widgets_RadioButton(RadioButton)
  EcsPayload_ui_widgets_Popover(Popover)
  EcsPayload_ui_widgets_Slider(Slider)
  EcsPayload_ui_widgets_SliderThumb(SliderThumb)
  EcsPayload_ui_widgets_SliderValue(SliderValue)
  EcsPayload_ui_widgets_SliderRange(SliderRange)
  EcsPayload_ui_widgets_SliderStep(SliderStep)
  EcsPayload_ui_widgets_SliderPrecision(SliderPrecision)
  EcsPayload_ui_widgets_SetSliderValue(SetSliderValue)
  EcsPayload_ui_widgets_Scrollbar(Scrollbar)
  EcsPayload_ui_widgets_CoreScrollbarThumb(CoreScrollbarThumb)
  EcsPayload_ui_widgets_CoreScrollbarDragState(CoreScrollbarDragState)
  EcsPayload_ui_widgets_Checkbox(Checkbox)
  EcsPayload_ui_widgets_SetChecked(SetChecked)
  EcsPayload_ui_widgets_ToggleChecked(ToggleChecked)
  EcsPayload_ui_widgets_Activate(Activate)
  EcsPayload_ui_widgets_ValueChange(ValueChangePayload)
  EcsPayload_ui_widgets_UiWidgetsPluginMarker(UiWidgetsPluginMarker)
  EcsPayload_ui_widgets_MenuEvent(MenuEvent)
  EcsPayload_ui_widgets_MenuPopup(MenuPopup)
  EcsPayload_ui_widgets_MenuItem(MenuItem)
}

///|
pub(all) struct ValueChangePayload {
  source : @core.Entity
  value : @ecs.EcsPayload
}

///|
pub impl @ecs.EcsPayloadCodec for InteractionDisabled with to_ecs_payload(self) {
  EcsPayload_ui_widgets_InteractionDisabled(self)
}

///|
pub impl @ecs.EcsPayloadCodec for InteractionDisabled with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_widgets_InteractionDisabled(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Pressed with to_ecs_payload(self) {
  EcsPayload_ui_widgets_Pressed(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Pressed with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_Pressed(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Checkable with to_ecs_payload(self) {
  EcsPayload_ui_widgets_Checkable(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Checkable with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_Checkable(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Checked with to_ecs_payload(self) {
  EcsPayload_ui_widgets_Checked(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Checked with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_Checked(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RadioGroup with to_ecs_payload(self) {
  EcsPayload_ui_widgets_RadioGroup(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RadioGroup with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_RadioGroup(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RadioButton with to_ecs_payload(self) {
  EcsPayload_ui_widgets_RadioButton(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RadioButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_RadioButton(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Popover with to_ecs_payload(self) {
  EcsPayload_ui_widgets_Popover(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Popover with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_Popover(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Slider with to_ecs_payload(self) {
  EcsPayload_ui_widgets_Slider(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Slider with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_Slider(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SliderThumb with to_ecs_payload(self) {
  EcsPayload_ui_widgets_SliderThumb(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SliderThumb with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_SliderThumb(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SliderValue with to_ecs_payload(self) {
  EcsPayload_ui_widgets_SliderValue(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SliderValue with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_SliderValue(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SliderRange with to_ecs_payload(self) {
  EcsPayload_ui_widgets_SliderRange(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SliderRange with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_SliderRange(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SliderStep with to_ecs_payload(self) {
  EcsPayload_ui_widgets_SliderStep(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SliderStep with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_SliderStep(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SliderPrecision with to_ecs_payload(self) {
  EcsPayload_ui_widgets_SliderPrecision(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SliderPrecision with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_SliderPrecision(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SetSliderValue with to_ecs_payload(self) {
  EcsPayload_ui_widgets_SetSliderValue(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SetSliderValue with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_SetSliderValue(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Scrollbar with to_ecs_payload(self) {
  EcsPayload_ui_widgets_Scrollbar(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Scrollbar with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_Scrollbar(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CoreScrollbarThumb with to_ecs_payload(self) {
  EcsPayload_ui_widgets_CoreScrollbarThumb(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CoreScrollbarThumb with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_widgets_CoreScrollbarThumb(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CoreScrollbarDragState with to_ecs_payload(
  self,
) {
  EcsPayload_ui_widgets_CoreScrollbarDragState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CoreScrollbarDragState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_widgets_CoreScrollbarDragState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Checkbox with to_ecs_payload(self) {
  EcsPayload_ui_widgets_Checkbox(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Checkbox with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_Checkbox(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SetChecked with to_ecs_payload(self) {
  EcsPayload_ui_widgets_SetChecked(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SetChecked with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_SetChecked(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ToggleChecked with to_ecs_payload(self) {
  EcsPayload_ui_widgets_ToggleChecked(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ToggleChecked with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_ToggleChecked(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Activate with to_ecs_payload(self) {
  EcsPayload_ui_widgets_Activate(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Activate with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_Activate(value) => Some(value)
    _ => None
  }
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for ValueChange[T] with to_ecs_payload(
  self,
) {
  EcsPayload_ui_widgets_ValueChange(ValueChangePayload::{
    source: self.source,
    value: T::to_ecs_payload(self.value),
  })
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for ValueChange[T] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_widgets_ValueChange(value) =>
      match T::from_ecs_payload(value.value) {
        Some(decoded) =>
          Some(ValueChange::{ source: value.source, value: decoded })
        None => None
      }
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for UiWidgetsPluginMarker with to_ecs_payload(
  self,
) {
  EcsPayload_ui_widgets_UiWidgetsPluginMarker(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UiWidgetsPluginMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ui_widgets_UiWidgetsPluginMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MenuEvent with to_ecs_payload(self) {
  EcsPayload_ui_widgets_MenuEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MenuEvent with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_MenuEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MenuPopup with to_ecs_payload(self) {
  EcsPayload_ui_widgets_MenuPopup(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MenuPopup with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_MenuPopup(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MenuItem with to_ecs_payload(self) {
  EcsPayload_ui_widgets_MenuItem(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MenuItem with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ui_widgets_MenuItem(value) => Some(value)
    _ => None
  }
}
