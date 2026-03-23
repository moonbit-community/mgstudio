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
test "app: render sub app runs with main app update" {
  let log : Array[String] = []
  let render_sub_app = SubApp::new(@ecs.World::new())
    .set_update_schedule(Some(Main))
    .add_systems(Update, system(fn(_world : @ecs.World) { log.push("render") }))
  let app = App::new(@ecs.World::new())
    .add_system(fn(_world : @ecs.World) { log.push("main") })
    .insert_sub_app(RenderApp, render_sub_app)
  app.run_once() |> ignore
  inspect(
    log.length() == 2 && log[0] == "main" && log[1] == "render",
    content="true",
  )
}

///|
test "app: sub app mut accessor writes back to app" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).insert_sub_app(
    RenderApp,
    SubApp::new(@ecs.World::new()).set_update_schedule(Some(Main)),
  )
  if app.get_sub_app_mut(RenderApp) is Some(sub_app_ref) {
    sub_app_ref.val = sub_app_ref.val.add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push(1) }),
    )
  }
  app.run_once() |> ignore
  inspect(log.length(), content="1")
}

///|
test "app: sub app extractor updates both main and render worlds" {
  let app = App::new(@ecs.World::new()).insert_sub_app(
    RenderApp,
    SubApp::new(@ecs.World::new()).set_update_schedule(Some(Main)),
  )
  let app = app.set_sub_app_extract(RenderApp, fn(
    main_world : @ecs.World,
    sub_world : @ecs.World,
  ) {
    let next_main = main_world
    let next_sub = sub_world
    for _ in 0..<7 {
      next_main.advance_sequence() |> ignore
    }
    for _ in 0..<11 {
      next_sub.advance_sequence() |> ignore
    }
    (next_main, next_sub)
  })
  let app = app.run_once()
  let sub_app = app.get_sub_app(RenderApp).unwrap()
  inspect(app.world().read_sequence(), content="9")
  inspect(sub_app.world().read_sequence(), content="12")
}
