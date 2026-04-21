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
test "pbr: WireframeConfig can be accessed through ResMut" {
  let observed : Ref[Bool?] = Ref::new(None)
  let app = @app.App::new(@ecs.World::new())
    .insert_resource(WireframeConfig::default())
    .add_system_param(fn(config : @app.ResMut[WireframeConfig]) {
      observed.val = Some(config.get().global)
      config.update(fn(value) { value.with_global(true) })
    })

  app.run_once() |> ignore

  debug_inspect(observed.val, content="Some(false)")
  debug_inspect(
    (try! app.world().get_resource(WireframeConfig::resource())).map(fn(
      config,
    ) {
      config.global
    }),
    content="Some(true)",
  )
}
