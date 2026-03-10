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
/// Reflection boundary aligned with Bevy's `bevy_reflect` responsibilities.
/// MoonBit runtime storage is mapped to `tonyfettes/any`.

///|
pub type Reflect = @any.Any

///|
pub type TypeId = @any.TypeId

///|
pub type TypeInfo = @any.TypeInfo

///|
pub type TypeMismatch = @any.TypeMismatch

///|
pub fn[T] reflect(value : T) -> Reflect {
  @any.Any::of(value)
}

///|
pub fn[T] try_to(value : Reflect) -> T? {
  @any.Any::try_to(value)
}

///|
pub fn[T] to(value : Reflect) -> T raise TypeMismatch {
  @any.Any::to(value)
}

///|
pub fn type_id(value : Reflect) -> TypeId {
  @any.Any::type_id(value)
}

///|
pub fn type_info(value : Reflect) -> TypeInfo {
  @any.Any::type_info(value)
}

///|
pub fn type_name(value : Reflect) -> String {
  @any.Any::type_name(value)
}
