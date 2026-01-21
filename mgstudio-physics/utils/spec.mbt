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
#declaration_only
pub type HashMap

///|
#declaration_only
pub fn HashMap::from_array(items : Array[(Int, String)]) -> HashMap {
  ...
}

///|
#declaration_only
pub fn HashMap::equals(self : HashMap, other : HashMap) -> Bool {
  ...
}

///|
#declaration_only
pub fn serialize_to_vec_tuple(target : HashMap) -> String {
  ...
}

///|
#declaration_only
pub fn deserialize_from_vec_tuple(value : String) -> HashMap {
  ...
}
