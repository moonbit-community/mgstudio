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

// Bevy source-shape anchor: bevy_derive/src/enum_variant_meta.rs

pub struct EnumVariantMeta {
  enum_name : String
  variant_name : String
}

pub fn EnumVariantMeta::debug_label(self : EnumVariantMeta) -> String {
  "\(self.enum_name)::\(self.variant_name)"
}
