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
/// Ported from rapier query filter groups.
test "query filter groups" {
  let groups = @dynamics.InteractionGroups::new(
    @dynamics.Group::group_1(),
    @dynamics.Group::group_2(),
    @dynamics.InteractionTestMode::And,
  )
  let filter = QueryFilter::new().groups(groups)
  if filter.groups_filter() is Some(current) {
    inspect(
      current.memberships().equals(@dynamics.Group::group_1()),
      content="true",
    )
    inspect(current.filter().equals(@dynamics.Group::group_2()), content="true")
  } else {
    inspect(false, content="true")
  }
}
