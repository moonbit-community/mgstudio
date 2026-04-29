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
test "text: font size units and selectors follow the Bevy-shaped surface" {
  let viewport = @math.Vec2::new(200.0F, 100.0F)

  debug_inspect(
    FontSize::Px(12.0F).eval(viewport, 18.0F) == 12.0F,
    content="true",
  )
  debug_inspect(
    FontSize::Vw(10.0F).eval(viewport, 18.0F) == 20.0F,
    content="true",
  )
  debug_inspect(
    FontSize::Vh(10.0F).eval(viewport, 18.0F) == 10.0F,
    content="true",
  )
  debug_inspect(
    FontSize::VMin(10.0F).eval(viewport, 18.0F) == 10.0F,
    content="true",
  )
  debug_inspect(
    FontSize::VMax(10.0F).eval(viewport, 18.0F) == 20.0F,
    content="true",
  )
  debug_inspect(
    FontSize::Rem(2.0F).eval(viewport, 18.0F) == 36.0F,
    content="true",
  )
  debug_inspect(FontWeight::VALUE(1200).clamp().raw_value(), content="1000")
  debug_inspect(FontWeight::VALUE(-5).clamp().raw_value(), content="400")
  debug_inspect(FontWidth::SEMI_EXPANDED.percentage(), content="112.5")
  debug_inspect(
    match FontStyle::Oblique(Some(17.5F)) {
      FontStyle::Oblique(Some(angle)) => angle == 17.5F
      _ => false
    },
    content="true",
  )
}

///|
test "text: font features and family mapping cover the Bevy-facing selectors" {
  let features = FontFeatures::builder()
    .enable(FontFeatureTag::SMALL_CAPS)
    .set(FontFeatureTag::FRACTIONS, 3U)
    .build()
  let cosmic_features = font_features_to_cosmic(features)
  let feature_list = cosmic_features.features()

  debug_inspect(feature_list.length(), content="2")
  debug_inspect(
    feature_list[0] == @cosmic.Feature::new(@cosmic.FeatureTag::new("smcp"), 1U),
    content="true",
  )
  debug_inspect(
    feature_list[1] == @cosmic.Feature::new(@cosmic.FeatureTag::new("frac"), 3U),
    content="true",
  )
  debug_inspect(
    text_font_source_family(FontSource::UiSansSerif)
    is Some(@cosmic.Family::UiSansSerif),
    content="true",
  )
  debug_inspect(
    text_font_source_family(FontSource::FangSong)
    is Some(@cosmic.Family::FangSong),
    content="true",
  )
}

///|
test "text: font hinting follows Bevy component and atlas-key semantics" {
  debug_inspect(FontHinting::default() is FontHinting::Disabled, content="true")
  debug_inspect(FontHinting::Disabled.should_hint(), content="false")
  debug_inspect(FontHinting::Enabled.should_hint(), content="true")

  let disabled_key = FontAtlasKey::new(
    1,
    12.0F,
    FontHinting::Disabled,
    FontSmoothing::AntiAliased,
  )
  let enabled_key = FontAtlasKey::new(
    1,
    12.0F,
    FontHinting::Enabled,
    FontSmoothing::AntiAliased,
  )
  debug_inspect(
    font_atlas_key_equals(disabled_key, enabled_key),
    content="false",
  )

  reset_text_ecs_test_state()
  let handle = text_spawn(
    Text2dBundle::new(
      Text2d::new("Hinted"),
      TextFont::from_font_size(0.0F),
      @transform.Transform::identity(),
    ).with_font_hinting(FontHinting::Enabled),
  )
  text_state.val.texts[0] = text_update_layout(text_state.val.texts[0])
  debug_inspect(
    text_state.val.texts[0].computed.font_hinting is FontHinting::Enabled,
    content="true",
  )
  text_set_font_hinting(handle, FontHinting::Disabled)
  text_state.val.texts[0] = text_update_layout(text_state.val.texts[0])
  debug_inspect(
    text_state.val.texts[0].computed.font_hinting is FontHinting::Disabled,
    content="true",
  )
}

///|
test "text: layout tracks viewport and rem dependencies for UI text" {
  reset_text_ecs_test_state()
  let viewport_font = TextFont::{
    ..TextFont::default(),
    font: FontSource::UiSansSerif,
    font_size: FontSize::Vh(10.0F),
  }
  let rem_font = TextFont::{
    ..TextFont::default(),
    font: FontSource::UiSansSerif,
    font_size: FontSize::Rem(1.5F),
  }

  let viewport_handle = text_spawn(
    Text2dBundle::new(
      Text2d::new("Viewport text"),
      viewport_font,
      @transform.Transform::identity(),
    ),
  )
  text_state.val.texts[0] = text_update_layout(text_state.val.texts[0])
  debug_inspect(
    text_state.val.texts[0].layout_info.glyphs.length(),
    content="0",
  )
  debug_inspect(
    text_state.val.texts[0].computed.uses_viewport_sizes,
    content="true",
  )
  text_set_logical_viewport_size(
    viewport_handle,
    Some(@math.Vec2::new(300.0F, 200.0F)),
  )
  text_state.val.texts[0] = text_update_layout(text_state.val.texts[0])
  debug_inspect(
    text_state.val.texts[0].computed.uses_viewport_sizes,
    content="true",
  )
  debug_inspect(
    text_state.val.texts[0].computed.uses_rem_sizes,
    content="false",
  )
  debug_inspect(
    text_state.val.texts[0].computed.buffer.font_size == 20.0F,
    content="true",
  )

  text_set_logical_viewport_size(
    viewport_handle,
    Some(@math.Vec2::new(300.0F, 400.0F)),
  )
  debug_inspect(
    text_layout_needs_update(text_state.val.texts[0]),
    content="true",
  )
  text_state.val.texts[0] = text_update_layout(text_state.val.texts[0])
  debug_inspect(
    text_state.val.texts[0].computed.buffer.font_size == 40.0F,
    content="true",
  )

  let rem_handle = text_spawn(
    Text2dBundle::new(
      Text2d::new("Rem text"),
      rem_font,
      @transform.Transform::identity(),
    ),
  )
  text_set_runtime_rem_size(18.0F)
  text_state.val.texts[1] = text_update_layout(text_state.val.texts[1])
  debug_inspect(
    text_state.val.texts[1].computed.uses_viewport_sizes,
    content="false",
  )
  debug_inspect(text_state.val.texts[1].computed.uses_rem_sizes, content="true")
  debug_inspect(
    text_state.val.texts[1].computed.buffer.font_size == 27.0F,
    content="true",
  )

  text_set_runtime_rem_size(12.0F)
  debug_inspect(
    text_layout_needs_update(text_state.val.texts[1]),
    content="true",
  )
  text_state.val.texts[1] = text_update_layout(text_state.val.texts[1])
  debug_inspect(
    text_state.val.texts[1].computed.buffer.font_size == 18.0F,
    content="true",
  )
  debug_inspect(text_get_content(rem_handle), content="Some(\"Rem text\")")
}
