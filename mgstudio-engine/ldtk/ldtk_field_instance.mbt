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
pub type FieldInstance = LdtkFieldInstance

///|
pub fn FieldInstance::new(
  identifier : String,
  tile : TilesetRectangle?,
  field_instance_type : String,
  value : FieldValue,
  def_uid : Int,
  real_editor_values : Array[Json?],
) -> FieldInstance {
  LdtkFieldInstance::{
    identifier,
    tile,
    field_instance_type,
    value,
    def_uid,
    real_editor_values,
  }
}
