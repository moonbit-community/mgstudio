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
fn rule_rank(rule : CoefficientCombineRule) -> Int {
  match rule {
    CoefficientCombineRule::Average => 0
    CoefficientCombineRule::Min => 1
    CoefficientCombineRule::Multiply => 2
    CoefficientCombineRule::Max => 3
    CoefficientCombineRule::ClampedSum => 4
  }
}

///|
fn max_rule(
  left : CoefficientCombineRule,
  right : CoefficientCombineRule,
) -> CoefficientCombineRule {
  if rule_rank(left) >= rule_rank(right) {
    left
  } else {
    right
  }
}

///|
pub fn CoefficientCombineRule::combine(
  coeff1 : @core.Real,
  coeff2 : @core.Real,
  rule_value1 : CoefficientCombineRule,
  rule_value2 : CoefficientCombineRule,
) -> @core.Real {
  let effective_rule = max_rule(rule_value1, rule_value2)
  match effective_rule {
    CoefficientCombineRule::Average => (coeff1 + coeff2) / 2.0F
    CoefficientCombineRule::Min => {
      let min_value = if coeff1 < coeff2 { coeff1 } else { coeff2 }
      @core.abs(min_value)
    }
    CoefficientCombineRule::Multiply => coeff1 * coeff2
    CoefficientCombineRule::Max => if coeff1 > coeff2 { coeff1 } else { coeff2 }
    CoefficientCombineRule::ClampedSum => {
      let sum = coeff1 + coeff2
      if sum < 0.0F {
        0.0F
      } else if sum > 1.0F {
        1.0F
      } else {
        sum
      }
    }
  }
}
