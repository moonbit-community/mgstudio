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
pub(all) enum Justify {
  Left
  Center
  Right
  Justified
  Start
  End
}

///|
pub(all) enum LineBreak {
  WordBoundary
  AnyCharacter
  WordOrCharacter
  NoWrap
}

///| Y-axis orientation for text layout coordinates.

///| - `TopToBottom`: origin at top-left, +Y goes down (UI-style layout).

///|
/// - `BottomToTop`: origin at bottom-left, +Y goes up (world-style layout).
pub(all) enum YAxisOrientation {
  TopToBottom
  BottomToTop
} derive(Eq, Debug)

///|
pub struct TextLayout {
  justify : Justify
  linebreak : LineBreak
}

///|
pub fn TextLayout::TextLayout() -> TextLayout {
  { justify: Left, linebreak: WordBoundary }
}

///|
pub fn TextLayout::new(justify : Justify, linebreak : LineBreak) -> TextLayout {
  { justify, linebreak }
}

///|
pub fn TextLayout::new_with_justify(justify : Justify) -> TextLayout {
  { ..TextLayout(), justify, }
}

///|
pub fn TextLayout::new_with_linebreak(linebreak : LineBreak) -> TextLayout {
  { ..TextLayout(), linebreak, }
}

///|
pub fn TextLayout::new_with_no_wrap() -> TextLayout {
  TextLayout::new_with_linebreak(NoWrap)
}

///|
pub fn TextLayout::with_justify(
  self : TextLayout,
  justify : Justify,
) -> TextLayout {
  { ..self, justify, }
}

///|
pub fn TextLayout::with_linebreak(
  self : TextLayout,
  linebreak : LineBreak,
) -> TextLayout {
  { ..self, linebreak, }
}

///|
pub fn TextLayout::with_no_wrap(self : TextLayout) -> TextLayout {
  { ..self, linebreak: NoWrap }
}

///|
pub(all) enum FontSmoothing {
  None
  AntiAliased
}

///|
pub fn FontSmoothing::default() -> FontSmoothing {
  AntiAliased
}

///|
pub(all) enum FontHinting {
  Disabled
  Enabled
}

///|
pub fn FontHinting::default() -> FontHinting {
  Disabled
}

///|
pub fn FontHinting::should_hint(self : FontHinting) -> Bool {
  match self {
    Disabled => false
    Enabled => true
  }
}

///|
pub(open) trait IntoFontSource {
  fn into_font_source(self : Self) -> FontSource
}

///|
pub(open) trait IntoFontSize {
  fn into_font_size(self : Self) -> FontSize
}

///|
pub(all) enum FontSource {
  Handle(@asset.Handle[@asset.Font])
  Family(String)
  Serif
  SansSerif
  Cursive
  Fantasy
  Monospace
  SystemUi
  UiSerif
  UiSansSerif
  UiMonospace
  UiRounded
  Emoji
  Math
  FangSong
}

///|
pub fn FontSource::default() -> FontSource {
  Handle(@asset.Handle::new(-1))
}

///|
pub fn FontSource::from_font(font : @asset.Handle[@asset.Font]) -> FontSource {
  Handle(font)
}

///|
pub fn FontSource::from_family(family : String) -> FontSource {
  Family(family)
}

///|
pub impl IntoFontSource for FontSource with fn into_font_source(self) {
  self
}

///|
pub impl IntoFontSource for @asset.Handle[@asset.Font] with fn into_font_source(
  self,
) {
  Handle(self)
}

///|
pub impl IntoFontSource for String with fn into_font_source(self) {
  Family(self)
}

///|
pub(all) enum FontSize {
  Px(Float)
  Vw(Float)
  Vh(Float)
  VMin(Float)
  VMax(Float)
  Rem(Float)
}

///|
pub fn FontSize::default() -> FontSize {
  Px(20.0)
}

///|
pub fn FontSize::eval(
  self : FontSize,
  logical_viewport_size : @math.Vec2,
  rem_size : Float,
) -> Float {
  match self {
    Px(value) => value
    Vw(value) => logical_viewport_size.x * value / 100.0
    Vh(value) => logical_viewport_size.y * value / 100.0
    VMin(value) => {
      let min_dim = if logical_viewport_size.x < logical_viewport_size.y {
        logical_viewport_size.x
      } else {
        logical_viewport_size.y
      }
      min_dim * value / 100.0
    }
    VMax(value) => {
      let max_dim = if logical_viewport_size.x > logical_viewport_size.y {
        logical_viewport_size.x
      } else {
        logical_viewport_size.y
      }
      max_dim * value / 100.0
    }
    Rem(value) => rem_size * value
  }
}

///|
pub fn FontSize::uses_viewport_size(self : FontSize) -> Bool {
  match self {
    Vw(_) => true
    Vh(_) => true
    VMin(_) => true
    VMax(_) => true
    _ => false
  }
}

///|
pub fn FontSize::uses_rem_size(self : FontSize) -> Bool {
  match self {
    Rem(_) => true
    _ => false
  }
}

///|
pub impl IntoFontSize for FontSize with fn into_font_size(self) {
  self
}

///|
pub impl IntoFontSize for Float with fn into_font_size(self) {
  Px(self)
}

///|
pub struct RemSize {
  value : Float
}

///|
pub fn RemSize::RemSize() -> RemSize {
  { value: 20.0 }
}

///|
pub fn RemSize::new(value : Float) -> RemSize {
  { value, }
}

///|
pub fn RemSize::value(self : RemSize) -> Float {
  self.value
}

///|
pub struct FontCx {
  font_system : @cosmic.FontSystem
}

///|
pub fn FontCx::new() -> FontCx {
  { font_system: @cosmic.FontSystem::new() }
}

///|
pub fn FontCx::FontCx() -> FontCx {
  FontCx::new()
}

///|
pub fn FontCx::family_names(self : FontCx) -> Array[String] {
  let families : Array[String] = []
  for entry in self.font_system.fonts() {
    families.push(entry.family_name())
  }
  families
}

///|
pub(all) enum FontWeight {
  THIN
  EXTRA_LIGHT
  LIGHT
  NORMAL
  MEDIUM
  SEMIBOLD
  BOLD
  EXTRA_BOLD
  BLACK
  EXTRA_BLACK
  VALUE(Int)
}

///|
pub fn FontWeight::default() -> FontWeight {
  NORMAL
}

///|
pub fn FontWeight::raw_value(self : FontWeight) -> Int {
  match self {
    THIN => 100
    EXTRA_LIGHT => 200
    LIGHT => 300
    NORMAL => 400
    MEDIUM => 500
    SEMIBOLD => 600
    BOLD => 700
    EXTRA_BOLD => 800
    BLACK => 900
    EXTRA_BLACK => 950
    VALUE(value) => value
  }
}

///|
pub fn FontWeight::clamp(self : FontWeight) -> FontWeight {
  let raw = self.raw_value()
  if raw <= 0 {
    return NORMAL
  }
  if raw > 1000 {
    return VALUE(1000)
  }
  VALUE(raw)
}

///|
pub(all) enum FontWidth {
  ULTRA_CONDENSED
  EXTRA_CONDENSED
  CONDENSED
  SEMI_CONDENSED
  NORMAL
  SEMI_EXPANDED
  EXPANDED
  EXTRA_EXPANDED
  ULTRA_EXPANDED
  VALUE(Float)
}

///|
pub fn FontWidth::default() -> FontWidth {
  NORMAL
}

///|
pub fn FontWidth::percentage(self : FontWidth) -> Float {
  match self {
    ULTRA_CONDENSED => 50.0
    EXTRA_CONDENSED => 62.5
    CONDENSED => 75.0
    SEMI_CONDENSED => 87.5
    NORMAL => 100.0
    SEMI_EXPANDED => 112.5
    EXPANDED => 125.0
    EXTRA_EXPANDED => 150.0
    ULTRA_EXPANDED => 200.0
    VALUE(value) => value
  }
}

///|
pub(all) enum FontStyle {
  Normal
  Italic
  Oblique(Float?)
}

///|
pub fn FontStyle::default() -> FontStyle {
  Normal
}

///|
pub(all) enum FontFeatureTag {
  STANDARD_LIGATURES
  CONTEXTUAL_LIGATURES
  DISCRETIONARY_LIGATURES
  CONTEXTUAL_ALTERNATES
  STYLISTIC_ALTERNATES
  SMALL_CAPS
  CAPS_TO_SMALL_CAPS
  SWASH
  TITLING_ALTERNATES
  FRACTIONS
  ORDINALS
  SLASHED_ZERO
  SUPERSCRIPT
  SUBSCRIPT
  OLDSTYLE_FIGURES
  LINING_FIGURES
  PROPORTIONAL_FIGURES
  TABULAR_FIGURES
  WEIGHT
  WIDTH
  SLANT
  RAW(String)
}

///|
pub fn FontFeatureTag::tag_string(self : FontFeatureTag) -> String {
  match self {
    STANDARD_LIGATURES => "liga"
    CONTEXTUAL_LIGATURES => "clig"
    DISCRETIONARY_LIGATURES => "dlig"
    CONTEXTUAL_ALTERNATES => "calt"
    STYLISTIC_ALTERNATES => "salt"
    SMALL_CAPS => "smcp"
    CAPS_TO_SMALL_CAPS => "c2sc"
    SWASH => "swsh"
    TITLING_ALTERNATES => "titl"
    FRACTIONS => "frac"
    ORDINALS => "ordn"
    SLASHED_ZERO => "zero"
    SUPERSCRIPT => "sups"
    SUBSCRIPT => "subs"
    OLDSTYLE_FIGURES => "onum"
    LINING_FIGURES => "lnum"
    PROPORTIONAL_FIGURES => "pnum"
    TABULAR_FIGURES => "tnum"
    WEIGHT => "wght"
    WIDTH => "wdth"
    SLANT => "slnt"
    RAW(value) => value
  }
}

///|
pub struct FontFeatures {
  features : Array[(FontFeatureTag, UInt)]
}

///|
pub fn FontFeatures::FontFeatures() -> FontFeatures {
  { features: [] }
}

///|
pub fn FontFeatures::new() -> FontFeatures {
  FontFeatures()
}

///|
pub fn FontFeatures::builder() -> FontFeaturesBuilder {
  FontFeaturesBuilder()
}

///|
pub fn FontFeatures::features(
  self : FontFeatures,
) -> Array[(FontFeatureTag, UInt)] {
  self.features
}

///|
pub fn FontFeatures::from_tags(tags : Array[FontFeatureTag]) -> FontFeatures {
  let features : Array[(FontFeatureTag, UInt)] = []
  for tag in tags {
    features.push((tag, 1U))
  }
  { features, }
}

///|
pub struct FontFeaturesBuilder {
  features : Array[(FontFeatureTag, UInt)]
}

///|
pub fn FontFeaturesBuilder::FontFeaturesBuilder() -> FontFeaturesBuilder {
  { features: [] }
}

///|
pub fn FontFeaturesBuilder::enable(
  self : FontFeaturesBuilder,
  feature_tag : FontFeatureTag,
) -> FontFeaturesBuilder {
  self.set(feature_tag, 1U)
}

///|
pub fn FontFeaturesBuilder::disable(
  self : FontFeaturesBuilder,
  feature_tag : FontFeatureTag,
) -> FontFeaturesBuilder {
  self.set(feature_tag, 0U)
}

///|
pub fn FontFeaturesBuilder::set(
  self : FontFeaturesBuilder,
  feature_tag : FontFeatureTag,
  value : UInt,
) -> FontFeaturesBuilder {
  self.features.push((feature_tag, value))
  self
}

///|
pub fn FontFeaturesBuilder::build(self : FontFeaturesBuilder) -> FontFeatures {
  { features: self.features }
}

///|
pub(all) struct TextFont {
  mut font : FontSource
  mut font_size : FontSize
  mut weight : FontWeight
  mut width : FontWidth
  mut style : FontStyle
  mut font_smoothing : FontSmoothing
  mut font_features : FontFeatures
}

///|
pub fn TextFont::TextFont() -> TextFont {
  {
    font: FontSource::default(),
    font_size: FontSize::default(),
    weight: FontWeight::default(),
    width: FontWidth::default(),
    style: FontStyle::default(),
    font_smoothing: FontSmoothing::default(),
    font_features: FontFeatures(),
  }
}

///|
pub fn[S : IntoFontSize] TextFont::from_font_size(font_size : S) -> TextFont {
  { ..TextFont(), font_size: font_size.into_font_size() }
}

///|
pub fn TextFont::with_font(
  self : TextFont,
  font : @asset.Handle[@asset.Font],
) -> TextFont {
  { ..self, font: Handle(font) }
}

///|
pub fn TextFont::with_family(self : TextFont, family : String) -> TextFont {
  { ..self, font: Family(family) }
}

///|
pub fn[S : IntoFontSize] TextFont::with_font_size(
  self : TextFont,
  font_size : S,
) -> TextFont {
  { ..self, font_size: font_size.into_font_size() }
}

///|
pub fn TextFont::with_weight(self : TextFont, weight : FontWeight) -> TextFont {
  { ..self, weight, }
}

///|
pub fn TextFont::with_width(self : TextFont, width : FontWidth) -> TextFont {
  { ..self, width, }
}

///|
pub fn TextFont::with_style(self : TextFont, style : FontStyle) -> TextFont {
  { ..self, style, }
}

///|
pub fn TextFont::with_font_smoothing(
  self : TextFont,
  font_smoothing : FontSmoothing,
) -> TextFont {
  { ..self, font_smoothing, }
}

///|
pub fn TextFont::with_font_features(
  self : TextFont,
  font_features : FontFeatures,
) -> TextFont {
  { ..self, font_features, }
}

///|
fn font_source_to_cosmic_family(source : FontSource) -> @cosmic.Family? {
  match source {
    Family(name) => Some(Name(name))
    Serif => Some(Serif)
    SansSerif => Some(SansSerif)
    Cursive => Some(Cursive)
    Fantasy => Some(Fantasy)
    Monospace => Some(Monospace)
    SystemUi => Some(SystemUi)
    UiSerif => Some(UiSerif)
    UiSansSerif => Some(UiSansSerif)
    UiMonospace => Some(UiMonospace)
    UiRounded => Some(UiRounded)
    Emoji => Some(Emoji)
    Math => Some(Math)
    FangSong => Some(FangSong)
    Handle(_) => None
  }
}

///|
fn font_feature_tag_to_cosmic(tag : FontFeatureTag) -> @cosmic.FeatureTag {
  @cosmic.FeatureTag::new(tag.tag_string())
}

///|
fn font_features_to_cosmic(features : FontFeatures) -> @cosmic.FontFeatures {
  let cosmic_features = @cosmic.FontFeatures::new()
  for feature in features.features {
    cosmic_features.set(font_feature_tag_to_cosmic(feature.0), feature.1)
    |> ignore
  }
  cosmic_features
}

///|
fn font_weight_to_cosmic(weight : FontWeight) -> @cosmic.Weight {
  match weight.clamp() {
    THIN => @cosmic.Weight::new(100)
    EXTRA_LIGHT => @cosmic.Weight::new(200)
    LIGHT => @cosmic.Weight::new(300)
    NORMAL => @cosmic.Weight::normal()
    MEDIUM => @cosmic.Weight::new(500)
    SEMIBOLD => @cosmic.Weight::new(600)
    BOLD => @cosmic.Weight::bold()
    EXTRA_BOLD => @cosmic.Weight::new(800)
    BLACK => @cosmic.Weight::new(900)
    EXTRA_BLACK => @cosmic.Weight::new(950)
    VALUE(value) => @cosmic.Weight::new(value)
  }
}

///|
fn font_width_to_swash(width : FontWidth) -> @swash.Stretch {
  match width {
    ULTRA_CONDENSED => @swash.Stretch::ultra_condensed()
    EXTRA_CONDENSED => @swash.Stretch::extra_condensed()
    CONDENSED => @swash.Stretch::condensed()
    SEMI_CONDENSED => @swash.Stretch::semi_condensed()
    NORMAL => @swash.Stretch::normal()
    SEMI_EXPANDED => @swash.Stretch::semi_expanded()
    EXPANDED => @swash.Stretch::expanded()
    EXTRA_EXPANDED => @swash.Stretch::extra_expanded()
    ULTRA_EXPANDED => @swash.Stretch::ultra_expanded()
    VALUE(value) => @swash.Stretch::from_percentage(value.to_double())
  }
}

///|
fn font_style_to_swash(style : FontStyle) -> @swash.Style {
  match style {
    Normal => Normal
    Italic => Italic
    Oblique(None) => Oblique(@swash.ObliqueAngle::from_degrees(14.0))
    Oblique(Some(value)) =>
      Oblique(@swash.ObliqueAngle::from_degrees(value.to_double()))
  }
}

///|
pub(all) struct TextColor {
  mut color : @color.Color
}

///|
pub fn TextColor::new(color : @color.Color) -> TextColor {
  { color, }
}

///|
pub fn TextColor::TextColor() -> TextColor {
  TextColor::new(@color.Color::white())
}

///|
pub fn TextColor::black() -> TextColor {
  TextColor::new(@color.Color::black())
}

///|
pub fn TextColor::white() -> TextColor {
  TextColor::new(@color.Color::white())
}

///|
pub(all) struct TextBackgroundColor {
  mut color : @color.Color
}

///|
pub fn TextBackgroundColor::new(color : @color.Color) -> TextBackgroundColor {
  { color, }
}

///|
pub fn TextBackgroundColor::TextBackgroundColor() -> TextBackgroundColor {
  TextBackgroundColor::new(@color.Color::black())
}

///|
pub fn TextBackgroundColor::black() -> TextBackgroundColor {
  TextBackgroundColor::new(@color.Color::black())
}

///|
pub fn TextBackgroundColor::white() -> TextBackgroundColor {
  TextBackgroundColor::new(@color.Color::white())
}

///|
pub(all) struct UnderlineColor {
  mut color : @color.Color
}

///|
pub fn UnderlineColor::new(color : @color.Color) -> UnderlineColor {
  { color, }
}

///|
pub fn UnderlineColor::UnderlineColor() -> UnderlineColor {
  UnderlineColor::new(@color.Color::white())
}

///|
pub(all) struct StrikethroughColor {
  mut color : @color.Color
}

///|
pub fn StrikethroughColor::new(color : @color.Color) -> StrikethroughColor {
  { color, }
}

///|
pub fn StrikethroughColor::StrikethroughColor() -> StrikethroughColor {
  StrikethroughColor::new(@color.Color::white())
}

///|
pub struct Underline {}

///|
#warnings("-unnecessary_annotation")
pub fn Underline::Underline() -> Underline {
  Underline::{  }
}

///|
pub struct Strikethrough {}

///|
#warnings("-unnecessary_annotation")
pub fn Strikethrough::Strikethrough() -> Strikethrough {
  Strikethrough::{  }
}

///|
pub(all) enum LineHeight {
  Px(Float)
  RelativeToFont(Float)
}

///|
pub fn LineHeight::default() -> LineHeight {
  RelativeToFont(1.2F)
}

///|
pub fn LineHeight::eval(self : LineHeight, font_size : Float) -> Float {
  match self {
    Px(value) => value
    RelativeToFont(scale) => scale * font_size
  }
}

///|
pub(all) struct TextShadow {
  mut offset : @math.Vec2
  mut color : @color.Color
}

///|
pub fn TextShadow::new(offset : @math.Vec2, color : @color.Color) -> TextShadow {
  { offset, color }
}

///|
pub fn TextShadow::TextShadow() -> TextShadow {
  TextShadow::new(@math.Vec2::new(4.0F, -4.0F), @color.Color::black())
}

///|
pub fn TextShadow::with_offset(
  self : TextShadow,
  offset : @math.Vec2,
) -> TextShadow {
  { ..self, offset, }
}

///|
pub fn TextShadow::with_color(
  self : TextShadow,
  color : @color.Color,
) -> TextShadow {
  { ..self, color, }
}
