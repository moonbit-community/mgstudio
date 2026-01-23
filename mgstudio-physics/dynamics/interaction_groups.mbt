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
pub struct Group {
  value : Int
}

///|
pub fn Group::new(bits : Int) -> Group {
  { value: bits }
}

///|
pub fn Group::bits(self : Group) -> Int {
  self.value
}

///|
pub fn Group::equals(self : Group, other : Group) -> Bool {
  self.value == other.value
}

///|
pub fn Group::none() -> Group {
  Group::new(0)
}

///|
pub fn Group::all() -> Group {
  Group::new(-1)
}

///|
pub fn Group::group_1() -> Group {
  Group::new(1 << 0)
}

///|
pub fn Group::group_2() -> Group {
  Group::new(1 << 1)
}

///|
pub fn Group::group_3() -> Group {
  Group::new(1 << 2)
}

///|
pub fn Group::group_4() -> Group {
  Group::new(1 << 3)
}

///|
pub fn Group::group_5() -> Group {
  Group::new(1 << 4)
}

///|
pub fn Group::group_6() -> Group {
  Group::new(1 << 5)
}

///|
pub fn Group::group_7() -> Group {
  Group::new(1 << 6)
}

///|
pub fn Group::group_8() -> Group {
  Group::new(1 << 7)
}

///|
pub fn Group::group_9() -> Group {
  Group::new(1 << 8)
}

///|
pub fn Group::group_10() -> Group {
  Group::new(1 << 9)
}

///|
pub fn Group::group_11() -> Group {
  Group::new(1 << 10)
}

///|
pub fn Group::group_12() -> Group {
  Group::new(1 << 11)
}

///|
pub fn Group::group_13() -> Group {
  Group::new(1 << 12)
}

///|
pub fn Group::group_14() -> Group {
  Group::new(1 << 13)
}

///|
pub fn Group::group_15() -> Group {
  Group::new(1 << 14)
}

///|
pub fn Group::group_16() -> Group {
  Group::new(1 << 15)
}

///|
pub fn Group::or(self : Group, other : Group) -> Group {
  Group::new(self.value | other.value)
}

///|
pub fn Group::intersection(self : Group, other : Group) -> Group {
  Group::new(self.value & other.value)
}

///|
pub struct InteractionGroups {
  mut memberships : Group
  mut filter : Group
  test_mode : InteractionTestMode
}

///|
pub fn InteractionGroups::new(
  memberships : Group,
  filter : Group,
  test_mode : InteractionTestMode,
) -> InteractionGroups {
  { memberships, filter, test_mode }
}

///|
pub fn InteractionGroups::all() -> InteractionGroups {
  InteractionGroups::new(Group::all(), Group::all(), InteractionTestMode::And)
}

///|
pub fn InteractionGroups::none() -> InteractionGroups {
  InteractionGroups::new(Group::none(), Group::none(), InteractionTestMode::And)
}

///|
pub fn InteractionGroups::with_memberships(
  self : InteractionGroups,
  memberships : Group,
) -> InteractionGroups {
  self.memberships = memberships
  self
}

///|
pub fn InteractionGroups::with_filter(
  self : InteractionGroups,
  filter : Group,
) -> InteractionGroups {
  self.filter = filter
  self
}

///|
pub fn InteractionGroups::test_and(
  self : InteractionGroups,
  other : InteractionGroups,
) -> Bool {
  (self.memberships.bits() & other.filter.bits()) != 0 &&
  (other.memberships.bits() & self.filter.bits()) != 0
}

///|
pub fn InteractionGroups::test_or(
  self : InteractionGroups,
  other : InteractionGroups,
) -> Bool {
  (self.memberships.bits() & other.filter.bits()) != 0 ||
  (other.memberships.bits() & self.filter.bits()) != 0
}

///|
pub fn InteractionGroups::test_groups(
  self : InteractionGroups,
  other : InteractionGroups,
) -> Bool {
  match self.test_mode {
    InteractionTestMode::And => self.test_and(other)
    InteractionTestMode::Or =>
      match other.test_mode {
        InteractionTestMode::And => self.test_and(other)
        InteractionTestMode::Or => self.test_or(other)
      }
  }
}

///|
pub fn InteractionGroups::memberships(self : InteractionGroups) -> Group {
  self.memberships
}

///|
pub fn InteractionGroups::filter(self : InteractionGroups) -> Group {
  self.filter
}

///|
pub fn InteractionGroups::test_mode(
  self : InteractionGroups,
) -> InteractionTestMode {
  self.test_mode
}

///|
pub fn InteractionGroups::default() -> InteractionGroups {
  InteractionGroups::new(
    Group::group_1(),
    Group::all(),
    InteractionTestMode::And,
  )
}
