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
const CAMERA_SPEED : Float = 1000.0F

///|
const TILE_SIZE : Float = 64.0F

///|
const MAP_SIZE : Float = 640.0F

///|
let many_glyph_samples : Array[String] = [
  "ABCD", "ÀÁÂÃ", "ĤĦĨĪ", "ƀƁƂƃ", "ϠϢϤϦ", "ҊҌҎҐ",
]

///|
struct TextStats {
  mut print_timer : Float
}

///|
let text_stats_key : @ecs.ResourceKey[TextStats] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_text2d.TextStats",
)

///|
impl @app.Resource for TextStats with resource() {
  text_stats_key
}

///|
struct Args {
  mut many_glyphs : Bool
  mut many_font_sizes : Bool
  mut recompute : Bool
  mut no_frustum_culling : Bool
  mut center : Bool
}

///|
let args_key : @ecs.ResourceKey[Args] = @ecs.register_resource(
  debug_name="examples.stress_tests.many_text2d.Args",
)

///|
impl @app.Resource for Args with resource() {
  args_key
}

///|
fn TextStats::default() -> TextStats {
  { print_timer: 0.0F }
}

///|
fn parse_args() -> Args {
  let args = Args::{
    many_glyphs: false,
    many_font_sizes: false,
    recompute: false,
    no_frustum_culling: false,
    center: false,
  }
  for arg in @env.args() {
    match arg {
      "--many-glyphs" => args.many_glyphs = true
      "--many-font-sizes" => args.many_font_sizes = true
      "--recompute" => args.recompute = true
      "--no-frustum-culling" => args.no_frustum_culling = true
      "--center" => args.center = true
      _ => ()
    }
  }
  args
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn pseudo_rand(seed : Int) -> Float {
  let normalized = (seed * 1664525 + 1013904223) % 10_000
  let non_negative = if normalized < 0 {
    normalized + 10_000
  } else {
    normalized
  }
  float_from_int(non_negative) / 10_000.0F
}

///|
fn random_glyph_chunk(seed : Int) -> String {
  many_glyph_samples[seed % many_glyph_samples.length()]
}

///|
fn random_text(idx : Int, args : Args) -> String {
  if !args.many_glyphs {
    return "Bevy"
  }
  random_glyph_chunk(idx + 101)
}

///|
fn random_font_size(idx : Int, args : Args) -> Float {
  if !args.many_font_sizes {
    return 60.0F
  }
  match idx % 6 {
    0 => 10.0F
    1 => 20.0F
    2 => 30.0F
    3 => 40.0F
    4 => 50.0F
    _ => 60.0F
  }
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::default()
  window.present_mode = @window.PresentMode::AutoNoVsync
  window.resolution = @window.WindowResolution::new(1920, 1080).with_scale_factor_override(
    1.0F,
  )
  window
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  args_res : @app.Res[Args],
) -> Unit {
  let args = args_res.get()
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let half_x = (MAP_SIZE / 4.0F).to_int()
  let half_y = (MAP_SIZE / 4.0F).to_int()
  let text_entities : Array[
    (
      @text.Text2d,
      @text.TextFont,
      @text.TextColor,
      @text.TextLayout,
      @transform.Transform,
    ),
  ] = []

  for y in -half_y..<half_y {
    for x in -half_x..<half_x {
      let idx = (y + half_y) * (half_x * 2) + (x + half_x)
      let translation = @math.Vec3::new(
        float_from_int(x) * TILE_SIZE,
        float_from_int(y) * TILE_SIZE,
        pseudo_rand(idx + 11),
      )
      let rotation = @math.Quat::from_rotation_z(pseudo_rand(idx + 23))
      let scale = @math.Vec3::splat(pseudo_rand(idx + 37) * 2.0F)
      let justify = if args.center {
        @text.Justify::Center
      } else {
        @text.Justify::Left
      }
      text_entities.push(
        (
          @text.Text2d::new(random_text(idx, args)),
          @text.TextFont::default()
          .with_font(font)
          .with_font_size(random_font_size(idx, args)),
          @text.TextColor::new(
            @sprite.Color::hsl(pseudo_rand(idx + 53) * 360.0F, 0.8F, 0.8F),
          ),
          @text.TextLayout::new_with_justify(justify),
          @transform.Transform::from_xyz(
            translation.x,
            translation.y,
            translation.z,
          )
          .with_rotation(rotation)
          .with_scale(scale),
        ),
      )
    }
  }
  if args.no_frustum_culling {
    let uncullable : Array[
      (
        @text.Text2d,
        @text.TextFont,
        @text.TextColor,
        @text.TextLayout,
        @transform.Transform,
        @visibility.NoFrustumCulling,
      ),
    ] = []
    for bundle in text_entities {
      let (text, font, color, layout, transform) = bundle
      uncullable.push(
        (
          text,
          font,
          color,
          layout,
          transform,
          @visibility.NoFrustumCulling::default(),
        ),
      )
    }
    ignore(commands.spawn_batch(uncullable))
  } else {
    ignore(commands.spawn_batch(text_entities))
  }
}

///|
fn move_camera(
  time : @app.Res[@time.Time[Unit]],
  camera : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Camera2d],
  ],
) -> Unit {
  let dt = time.get().delta_secs()
  try! camera.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.rotate_z(dt * 0.5F)
    transform_ref.val.translation = transform_ref.val.translation.add(
      transform_ref.val.local_x().mul_scalar(CAMERA_SPEED * dt),
    )
  })
}

///|
fn recompute(texts : @ecs.Query[@ecs.Mut[@text.Text2d], @ecs.All]) -> Unit {
  try! texts.for_each(fn(_entity, text2d) { text2d.set(text2d.value()) })
}

///|
fn print_counts(
  time : @app.Res[@time.Time[Unit]],
  stats : @app.ResMut[TextStats],
  visible_texts : @ecs.Query[
    @ecs.Comp[@visibility.ViewVisibility],
    @ecs.With[@text.Text2d],
  ],
  atlas_set : @app.Res[@text.FontAtlasSet],
) -> Unit {
  let stats_ref = stats.get_ref()
  stats_ref.val.print_timer += time.get().delta_secs()
  if stats_ref.val.print_timer < 1.0F {
    return
  }
  stats_ref.val.print_timer -= 1.0F
  let mut atlas_count = 0
  for entry in atlas_set.get().entries {
    atlas_count += entry.atlases.length()
  }
  let mut visible_count = 0
  try! visible_texts.for_each(fn(_entity, visibility) {
    if visibility.value().is_visible() {
      visible_count += 1
    }
  })
  println(
    "Texts: \{visible_texts.count()} Visible: \{visible_count} Atlases: \{atlas_count} QueueItems: \{@sprite_render.render2d_diagnostic_queued_draw_item_count()} QueueCpuMs: \{@sprite_render.render2d_diagnostic_queue_cpu_ms()} ExecuteCpuMs: \{@sprite_render.render2d_diagnostic_execute_cpu_ms()} TextUpdateCpuMs: \{@text.text_diagnostic_update_cpu_ms()} TextPendingLayout: \{@text.text_diagnostic_update_pending_layout_count()} TextSyncCpuMs: \{@text.text_diagnostic_sync_ecs_cpu_ms()} TextSyncDirty: \{@text.text_diagnostic_sync_ecs_dirty_entity_count()} TextSyncEarlyReturn: \{@text.text_diagnostic_sync_ecs_early_return()} TextRenderCpuMs: \{@text.text_diagnostic_render_cpu_ms()} TextVisible: \{@text.text_diagnostic_render_visible_text_count()} TextCulled: \{@text.text_diagnostic_render_culled_text_count()} TextSubmitted: \{@text.text_diagnostic_render_submitted_item_count()}",
  )
}

///|
fn main {
  let args = parse_args()
  let app = @app.App::new(@ecs.World::new())
    .insert_resource(TextStats::default())
    .insert_resource(args)
    .insert_resource(@winit.WinitSettings::continuous())
    .add_plugins(
      @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
        primary_window: Some(configured_window()),
        primary_cursor_options: None,
        exit_condition: @window.ExitCondition::OnAllClosed,
        close_when_requested: true,
      }),
    )
    .add_plugins(@diagnostic.StressDiagnosticsPlugin::default())
    .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
    .add_systems(@app.Update, @app.system(@app.system_param2(move_camera)))
    .add_systems(@app.Update, @app.system(@app.system_param4(print_counts)))
  if args.recompute {
    app.add_systems(@app.Update, @app.system(@app.system_param(recompute)))
    |> ignore
  }
  app.run()
}
