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
  EcsPayload_text_Text(Text)
  EcsPayload_text_Text2d(Text2d)
  EcsPayload_text_TextSpan(TextSpan)
  EcsPayload_text_TextFont(TextFont)
  EcsPayload_text_TextColor(TextColor)
  EcsPayload_text_TextBackgroundColor(TextBackgroundColor)
  EcsPayload_text_UnderlineColor(UnderlineColor)
  EcsPayload_text_Underline(Underline)
  EcsPayload_text_StrikethroughColor(StrikethroughColor)
  EcsPayload_text_Strikethrough(Strikethrough)
  EcsPayload_text_TextLayout(TextLayout)
  EcsPayload_text_TextBounds(TextBounds)
  EcsPayload_text_LineHeight(LineHeight)
  EcsPayload_text_FontHinting(FontHinting)
  EcsPayload_text_Text2dShadow(Text2dShadow)
  EcsPayload_text_TextShadow(TextShadow)
  EcsPayload_text_YAxisOrientation(YAxisOrientation)
  EcsPayload_text_RemSize(RemSize)
  EcsPayload_text_FontCx(FontCx)
  EcsPayload_text_FontAtlasSet(FontAtlasSet)
}

///|
pub impl @ecs.EcsPayloadCodec for Text with to_ecs_payload(self) {
  EcsPayload_text_Text(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Text with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_Text(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Text2d with to_ecs_payload(self) {
  EcsPayload_text_Text2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Text2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_Text2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TextSpan with to_ecs_payload(self) {
  EcsPayload_text_TextSpan(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TextSpan with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_TextSpan(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TextFont with to_ecs_payload(self) {
  EcsPayload_text_TextFont(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TextFont with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_TextFont(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TextColor with to_ecs_payload(self) {
  EcsPayload_text_TextColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TextColor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_TextColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TextBackgroundColor with to_ecs_payload(self) {
  EcsPayload_text_TextBackgroundColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TextBackgroundColor with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_text_TextBackgroundColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for UnderlineColor with to_ecs_payload(self) {
  EcsPayload_text_UnderlineColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UnderlineColor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_UnderlineColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Underline with to_ecs_payload(self) {
  EcsPayload_text_Underline(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Underline with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_Underline(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for StrikethroughColor with to_ecs_payload(self) {
  EcsPayload_text_StrikethroughColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for StrikethroughColor with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_text_StrikethroughColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Strikethrough with to_ecs_payload(self) {
  EcsPayload_text_Strikethrough(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Strikethrough with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_Strikethrough(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TextLayout with to_ecs_payload(self) {
  EcsPayload_text_TextLayout(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TextLayout with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_TextLayout(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TextBounds with to_ecs_payload(self) {
  EcsPayload_text_TextBounds(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TextBounds with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_TextBounds(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LineHeight with to_ecs_payload(self) {
  EcsPayload_text_LineHeight(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LineHeight with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_LineHeight(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FontHinting with to_ecs_payload(self) {
  EcsPayload_text_FontHinting(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FontHinting with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_FontHinting(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Text2dShadow with to_ecs_payload(self) {
  EcsPayload_text_Text2dShadow(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Text2dShadow with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_Text2dShadow(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TextShadow with to_ecs_payload(self) {
  EcsPayload_text_TextShadow(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TextShadow with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_TextShadow(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for YAxisOrientation with to_ecs_payload(self) {
  EcsPayload_text_YAxisOrientation(self)
}

///|
pub impl @ecs.EcsPayloadCodec for YAxisOrientation with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_text_YAxisOrientation(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RemSize with to_ecs_payload(self) {
  EcsPayload_text_RemSize(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RemSize with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_RemSize(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FontCx with to_ecs_payload(self) {
  EcsPayload_text_FontCx(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FontCx with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_FontCx(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FontAtlasSet with to_ecs_payload(self) {
  EcsPayload_text_FontAtlasSet(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FontAtlasSet with from_ecs_payload(payload) {
  match payload {
    EcsPayload_text_FontAtlasSet(value) => Some(value)
    _ => None
  }
}
