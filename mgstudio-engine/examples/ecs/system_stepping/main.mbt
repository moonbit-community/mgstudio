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
const PRE_UPDATE_SYSTEM_NAME : String = "examples.ecs.system_stepping.pre_update"

///|
const UPDATE_SYSTEM_ONE_NAME : String = "examples.ecs.system_stepping.update_one"

///|
const UPDATE_SYSTEM_TWO_NAME : String = "examples.ecs.system_stepping.update_two"

///|
const UPDATE_SYSTEM_THREE_NAME : String = "examples.ecs.system_stepping.update_three"

///|
const UPDATE_SYSTEM_FOUR_NAME : String = "examples.ecs.system_stepping.update_four"

///|
fn named_system(
  name : String,
  system_fn : (@ecs.World) -> Unit,
) -> @app.SystemConfig[@ecs.World] {
  @app.system(system_fn).named(name).in_set(@app.system_set(name))
}

///|
fn main {
  let mut app = @app.App::new(@ecs.World::new())
    .add_systems(
      @app.PreUpdate,
      named_system(PRE_UPDATE_SYSTEM_NAME, pre_update_system),
    )
    .add_systems(
      @app.Update,
      named_system(UPDATE_SYSTEM_ONE_NAME, update_system_one),
    )
    .add_systems(
      @app.Update,
      named_system(UPDATE_SYSTEM_FOUR_NAME, update_system_four),
    )
    .add_systems(
      @app.Update,
      named_system(UPDATE_SYSTEM_TWO_NAME, update_system_two).after(
        @app.system_set(UPDATE_SYSTEM_ONE_NAME),
      ),
    )
    .add_systems(
      @app.Update,
      named_system(UPDATE_SYSTEM_THREE_NAME, update_system_three).after(
        @app.system_set(UPDATE_SYSTEM_TWO_NAME),
      ),
    )
    .insert_resource(@app.Stepping::new())

  println("\nActions: call app.update()\n Result: All systems run normally")
  app = app.update()

  println(
    "\nActions: add Update to Stepping, enable it, then call app.update()\n Result: Only PreUpdate runs while Update waits for an explicit step or continue",
  )
  let stepping = stepping_ref(app)
  stepping.set(stepping.peek().add_schedule(@app.Update).enable())
  app = app.update()

  println(
    "\nActions: call Stepping.step_frame(); call app.update()\n Result: PreUpdate runs, then one Update system runs",
  )
  stepping.set(stepping.peek().step_frame())
  app = app.update()

  println(
    "\nActions: call app.update()\n Result: Only PreUpdate runs again because the previous step only applied to one frame",
  )
  app = app.update()

  println(
    "\nActions: call Stepping.continue_frame(); call app.update()\n Result: PreUpdate runs, then the remaining Update systems run",
  )
  stepping.set(stepping.peek().continue_frame())
  app = app.update()

  println(
    "\nActions: mark update_system_two as always_run; step three frames\n Result: update_system_two runs every frame while the other Update systems step one by one",
  )
  stepping.set(stepping.peek().always_run(@app.Update, UPDATE_SYSTEM_TWO_NAME))
  for _ in 0..<3 {
    stepping.set(stepping.peek().step_frame())
    app = app.update()
  }

  println(
    "\nActions: mark update_system_two as never_run; continue one frame\n Result: all other Update systems run, but update_system_two stays skipped while stepping is enabled",
  )
  stepping.set(stepping.peek().never_run(@app.Update, UPDATE_SYSTEM_TWO_NAME))
  stepping.set(stepping.peek().continue_frame())
  app = app.update()

  println(
    "\nActions: set a breakpoint on update_system_two; continue, step, continue\n Result: continue stops before update_system_two, the step runs it, and the final continue resumes after it",
  )
  stepping.set(
    stepping
    .peek()
    .clear_schedule(@app.Update)
    .set_breakpoint(@app.Update, UPDATE_SYSTEM_TWO_NAME),
  )
  stepping.set(stepping.peek().continue_frame())
  app = app.update()
  stepping.set(stepping.peek().step_frame())
  app = app.update()
  stepping.set(stepping.peek().continue_frame())
  app = app.update()

  println(
    "\nActions: clear the breakpoint, disable stepping, then call app.update()\n Result: all systems run normally again",
  )
  stepping.set(
    stepping.peek().clear_breakpoint(@app.Update, UPDATE_SYSTEM_TWO_NAME),
  )
  stepping.set(stepping.peek().disable())
  app = app.update()
}

///|
fn stepping_ref(app : @app.App[@ecs.World]) -> @ecs.ResourceMut[@app.Stepping] {
  match (try! app.world().get_resource_mut(@app.Stepping::resource())) {
    Some(resource_ref) => resource_ref
    None => abort("Stepping resource should exist")
  }
}

///|
fn pre_update_system(_world : @ecs.World) -> Unit {
  println("▶ pre_update_system")
}

///|
fn update_system_one(_world : @ecs.World) -> Unit {
  println("▶ update_system_one")
}

///|
fn update_system_two(_world : @ecs.World) -> Unit {
  println("▶ update_system_two")
}

///|
fn update_system_three(_world : @ecs.World) -> Unit {
  println("▶ update_system_three")
}

///|
fn update_system_four(_world : @ecs.World) -> Unit {
  println("▶ update_system_four")
}
