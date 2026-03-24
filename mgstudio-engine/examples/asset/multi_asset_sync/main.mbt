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
/// Port of `bevy/examples/asset/multi_asset_sync.rs`.

///|
pub(all) enum LoadingState {
  Loading
  Loaded
} derive(Eq, Show)

///|
impl Default for LoadingState with default() {
  LoadingState::Loading
}

///|
impl @app.States for LoadingState with debug_name(self) {
  ignore(self)
  "examples.asset.multi_asset_sync.LoadingState"
}

///|
struct OneHundredThings {
  handles : Array[@asset.Handle[@scene.Gltf]]
}

///|
struct AssetBarrier {
  remaining : Ref[Int]
}

///|
struct AssetBarrierGuard {
  remaining : Ref[Int]
}

///|
struct AsyncLoadingState {
  ready : Ref[Bool]
}

///|
struct Loading {}

///|
struct LoadingText {}

///|
let one_hundred_things_key : @ecs.ResourceKey[OneHundredThings] = @ecs.register_resource(
  debug_name="examples.asset.multi_asset_sync.OneHundredThings",
)

///|
let asset_barrier_key : @ecs.ResourceKey[AssetBarrier] = @ecs.register_resource(
  debug_name="examples.asset.multi_asset_sync.AssetBarrier",
)

///|
let async_loading_state_key : @ecs.ResourceKey[AsyncLoadingState] = @ecs.register_resource(
  debug_name="examples.asset.multi_asset_sync.AsyncLoadingState",
)

///|
let loading_key : @ecs.ComponentKey[Loading] = @ecs.register_component(
  debug_name="examples.asset.multi_asset_sync.Loading",
)

///|
let loading_text_key : @ecs.ComponentKey[LoadingText] = @ecs.register_component(
  debug_name="examples.asset.multi_asset_sync.LoadingText",
)

///|
pub impl @app.Resource for OneHundredThings with resource() {
  one_hundred_things_key
}

///|
pub impl @app.Resource for AssetBarrier with resource() {
  asset_barrier_key
}

///|
pub impl @app.Resource for AsyncLoadingState with resource() {
  async_loading_state_key
}

///|
pub impl @ecs.Component for Loading with component() {
  loading_key
}

///|
pub impl @ecs.Component for LoadingText with component() {
  loading_text_key
}

///|
fn AsyncLoadingState::new() -> AsyncLoadingState {
  AsyncLoadingState::{ ready: Ref::new(false) }
}

///|
fn AsyncLoadingState::is_loaded(self : AsyncLoadingState) -> Bool {
  self.ready.val
}

///|
fn AsyncLoadingState::mark_loaded(self : AsyncLoadingState) -> Unit {
  self.ready.val = true
}

///|
fn AssetBarrier::new() -> (AssetBarrier, AssetBarrierGuard) {
  let remaining = Ref::new(1)
  (AssetBarrier::{ remaining, }, AssetBarrierGuard::{ remaining, })
}

///|
fn AssetBarrier::is_ready(self : AssetBarrier) -> Bool {
  self.remaining.val == 0
}

///|
fn AssetBarrierGuard::clone(self : AssetBarrierGuard) -> AssetBarrierGuard {
  self.remaining.val = self.remaining.val + 1
  AssetBarrierGuard::{ remaining: self.remaining }
}

///|
pub impl @asset.AssetLoadGuard for AssetBarrierGuard with release(self) {
  self.remaining.val = if self.remaining.val <= 0 {
    0
  } else {
    self.remaining.val - 1
  }
}

///|
fn scene_path_for_index(index : Int) -> String {
  match index % 5 {
    0 => "models/GolfBall/GolfBall.glb"
    1 => "models/AlienCake/alien.glb"
    2 => "models/AlienCake/cakeBirthday.glb"
    3 => "models/FlightHelmet/FlightHelmet.gltf"
    _ => "models/torus/torus.gltf"
  }
}

///|
fn setup_assets(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let (barrier, barrier_guard) = AssetBarrier::new()
  let loading_state = AsyncLoadingState::new()
  let gltf_handles : Array[@asset.Handle[@scene.Gltf]] = []
  for i in 0..<100 {
    gltf_handles.push(
      asset_server
      .get()
      .load_acquire(scene_path_for_index(i), barrier_guard.clone()),
    )
  }
  barrier_guard.release()

  commands.insert_resource(OneHundredThings::{ handles: gltf_handles })
  commands.insert_resource(barrier)
  commands.insert_resource(loading_state)

  @tasks.AsyncComputeTaskPool::get()
  .spawn(fn() {
    while !barrier.is_ready() {
      ()
    }
    loading_state.mark_loaded()
  })
  .detach()
}

///|
fn setup_ui(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        Loading::{  },
        LoadingText::{  },
        @text.Text::new("Loading..."),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
      ),
    ),
  )
}

///|
fn setup_scene(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(10.0F, 10.0F, 15.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 1_500.0F, true),
        @transform.Transform::from_rotation(
          @math.Quat::from_euler(
            @math.EulerRot::ZYX,
            0.0F,
            1.0F,
            -@math.pi() / 4.0F,
          ),
        ),
      ),
    ),
  )

  let plane_mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@pbr.mesh3d_geometry_plane(50_000.0F, 50_000.0F))
  let loading_material = materials.get_ref().val
    |> @pbr.add_material(@sprite.Color::srgb(0.7F, 0.2F, 0.2F))

  ignore(
    commands.spawn(
      (
        Loading::{  },
        @pbr.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(loading_material),
      ),
    ),
  )
}

///|
fn assets_loaded(world : @ecs.World) -> Bool {
  match (try! world.get_resource(asset_barrier_key)) {
    Some(barrier) => barrier.is_ready()
    None => false
  }
}

///|
fn wait_on_load(
  commands : @app.Commands,
  things : @app.Res[OneHundredThings],
  gltfs : @app.Res[@asset.Assets[@scene.Gltf]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let plane_mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@pbr.mesh3d_geometry_plane(50_000.0F, 50_000.0F))
  let loaded_material = materials.get_ref().val
    |> @pbr.add_material(@sprite.Color::srgb(0.3F, 0.5F, 0.3F))

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(loaded_material),
        @transform.Transform::from_translation(
          @math.Vec3::new(0.0F, 0.0F, -0.01F),
        ),
      ),
    ),
  )

  for i in 0..<10 {
    for j in 0..<10 {
      let index = i * 10 + j
      let position = @math.Vec3::new(
        Float::from_double(i.to_double()) - 5.0F,
        0.0F,
        Float::from_double(j.to_double()) - 5.0F,
      )
      let gltf_handle = things.get().handles[index]
      let gltf = match gltfs.get().get(gltf_handle) {
        Some(gltf) => gltf
        None => continue
      }
      if gltf.scenes.length() == 0 {
        continue
      }
      ignore(
        commands.spawn(
          (
            @scene.SceneRoot::new(gltf.scenes[0]),
            @transform.Transform::from_translation(position),
          ),
        ),
      )
    }
  }
}

///|
fn get_async_loading_state(
  state : @app.Res[AsyncLoadingState],
  barrier : @app.Res[AssetBarrier],
  text_query : @ecs.Query2[LoadingText, @text.Text],
) -> Unit {
  if !state.get().is_loaded() {
    if !barrier.get().is_ready() {
      return
    }
    state.get().mark_loaded()
  }
  @app.set_state(LoadingState::Loaded)
  try! text_query.view(fn(_entity, _marker, text) { text.content = "Loaded!" })
}

///|
fn despawn_loading_state_entities(
  commands : @app.Commands,
  loading : @ecs.Query1Filtered[Loading, @ecs.With[Loading]],
) -> Unit {
  try! loading.view(fn(entity, _loading) { commands.entity(entity).despawn() })
  commands.remove_world_resource(asset_barrier_key)
  commands.remove_world_resource(async_loading_state_key)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .insert_world_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 2_000.0F),
  )
  .insert_state(LoadingState::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup_assets)))
  .add_systems(@app.Startup, @app.system(@app.system_param(setup_ui)))
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup_scene)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param5(wait_on_load))
    .run_if(@app.in_state(LoadingState::Loading))
    .run_if(assets_loaded),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(get_async_loading_state)).run_if(
      @app.in_state(LoadingState::Loading),
    ),
  )
  .add_on_exit_system_config(
    LoadingState::Loading,
    @app.system(@app.system_param2(despawn_loading_state_entities)),
  )
  .run()
}
