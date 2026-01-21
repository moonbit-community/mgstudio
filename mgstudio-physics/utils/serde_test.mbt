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
/// Ported from rapier/src/utils/mod.rs (serde_json_hashmap).
test "serde json hashmap" {
  let map = HashMap::from_array([(42, "Forty-Two")])
  let serialized = serialize_to_vec_tuple(map)
  inspect(serialized, content="{\"map\":[[42,\"Forty-Two\"]]}")
  let parsed = deserialize_from_vec_tuple(serialized)
  inspect(parsed.equals(map), content="true")
}
