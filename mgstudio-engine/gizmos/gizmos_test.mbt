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
test "gizmos boundary re-exports configuration and plugin surface" {
  let app = @gizmos.init_gizmo_group(
    @app.App::new(@ecs.World::new()),
    @gizmos.DefaultGizmoConfigGroup::default(),
  )
  let _ = @gizmos.gizmo_plugin(app)
  inspect(
    app.contains_resource(@gizmos.GizmoConfigStore::resource()),
    content="true",
  )
  inspect("ok", content="ok")
}

///|
struct TestRoundGizmos {}

///|
impl Default for TestRoundGizmos with default() {
  TestRoundGizmos::{  }
}

///|
impl @sprite.GizmoConfigGroup for TestRoundGizmos with gizmo_config_group_marker(
  _self,
) {

}

///|
test "custom gizmo groups expose config through store and system param" {
  let seen_width = Ref::new(-1.0F)
  let app = @gizmos.init_gizmo_group(
    @app.App::new(@ecs.World::new()),
    TestRoundGizmos::default(),
  ).add_systems(
    @app.Update,
    @app.system(
      @app.system_param(fn(gizmos : @gizmos.Gizmos[TestRoundGizmos]) {
        seen_width.val = gizmos.config().line.width
      }),
    ),
  )

  match app.world().get_resource_ref_mut(@gizmos.GizmoConfigStore::resource()) {
    Some(store_ref) => {
      let (config_ref, _group_ref) = store_ref.val.config_mut(
        TestRoundGizmos::default(),
      )
      let current = config_ref.val
      config_ref.val = { ..current, line: { ..current.line, width: 7.0F } }
    }
    None => abort("Missing GizmoConfigStore resource in test")
  }

  ignore(app.update())
  inspect(seen_width.val, content="7")
}
