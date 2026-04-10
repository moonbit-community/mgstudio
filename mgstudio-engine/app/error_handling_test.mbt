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
struct ErrorHandlingResource {
  value : Int
} derive(Eq, Debug)

///|
struct ErrorHandlingMarker {} derive(Eq, Debug)

///|
let error_handling_resource_key : @ecs.ResourceKey[ErrorHandlingResource] = @ecs.register_resource(
  debug_name="tests.app.error_handling.resource",
)

///|
let error_handling_marker_key : @ecs.ComponentKey[ErrorHandlingMarker] = @ecs.register_component(
  debug_name="tests.app.error_handling.marker",
)

///|
pub impl Resource for ErrorHandlingResource with resource() {
  error_handling_resource_key
}

///|
pub impl @ecs.Component for ErrorHandlingMarker with component() {
  error_handling_marker_key
}

///|
fn touch_error_handling_types() -> Unit {
  ignore(ErrorHandlingResource::{ value: 0 })
  ignore(ErrorHandlingMarker::{  })
}

///|
suberror ErrorHandlingTestError {
  BodyFailure
  LocalFailure
}

///|
test "app error handling: default handler captures fallible system body errors" {
  touch_error_handling_types()
  let kinds : Array[ErrorContextKind] = []
  let sources : Array[String] = []
  let mut app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) {
      kinds.push(context.kind())
      sources.push(context.source())
    })
    .add_systems(
      Update,
      fallible_system(fn(_world : @ecs.World) raise { raise BodyFailure }),
    )

  app = app.run_once()

  debug_inspect(kinds.length(), content="1")
  debug_inspect(kinds[0] == ErrorContextKind::System, content="true")
  debug_inspect(sources[0], content="<anonymous system>")
}

///|
test "app error handling: missing Res routes invalid validation through default handler" {
  let kinds : Array[ErrorContextKind] = []
  let ran = Ref::new(false)
  let mut app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) { kinds.push(context.kind()) })
    .add_systems(
      Update,
      system(
        system_param(fn(_resource : Res[ErrorHandlingResource]) {
          ran.val = true
        }),
      ),
    )

  app = app.run_once()

  debug_inspect(ran.val, content="false")
  debug_inspect(kinds.length(), content="1")
  debug_inspect(kinds[0] == ErrorContextKind::Validation, content="true")
}

///|
test "app error handling: skipped validated params do not invoke error handlers" {
  let errors : Array[String] = []
  let ran = Ref::new(false)
  let mut app = App::new(@ecs.World::new())
    .set_error_handler(fn(error, _context) { errors.push(error.to_string()) })
    .add_systems(
      Update,
      system(
        system_param(fn(
          _marker : Single[@ecs.Comp[ErrorHandlingMarker], @ecs.All],
        ) {
          ran.val = true
        }),
      ),
    )

  app = app.run_once()

  debug_inspect(ran.val, content="false")
  debug_inspect(errors.length(), content="0")
}

///|
test "app error handling: per-system handler captures body errors" {
  let default_count = Ref::new(0)
  let local_count = Ref::new(0)
  let local_kinds : Array[ErrorContextKind] = []
  let mut app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, _context) {
      default_count.val = default_count.val + 1
    })
    .add_systems(
      Update,
      fallible_system(fn(_world : @ecs.World) raise { raise LocalFailure }).handle_error_with(fn(
          _error,
          context,
        ) {
          local_count.val = local_count.val + 1
          local_kinds.push(context.kind())
        },
      ),
    )

  app = app.run_once()

  debug_inspect(default_count.val, content="0")
  debug_inspect(local_count.val, content="1")
  debug_inspect(local_kinds.length(), content="1")
  debug_inspect(local_kinds[0] == ErrorContextKind::System, content="true")
}

///|
test "app error handling: per-system handler does not intercept validation failures" {
  let default_kinds : Array[ErrorContextKind] = []
  let local_kinds : Array[ErrorContextKind] = []
  let mut app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) {
      default_kinds.push(context.kind())
    })
    .add_systems(
      Update,
      system(system_param(fn(_resource : Res[ErrorHandlingResource]) {  })).handle_error_with(fn(
          _error,
          context,
        ) {
          local_kinds.push(context.kind())
        },
      ),
    )

  app = app.run_once()

  debug_inspect(local_kinds.length(), content="0")
  debug_inspect(default_kinds.length(), content="1")
  debug_inspect(
    default_kinds[0] == ErrorContextKind::Validation,
    content="true",
  )
}
