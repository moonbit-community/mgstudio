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
test "curve: interval spaced_points follows bounded interval layout" {
  let values = Interval::new(-1.0F, 1.0F).unwrap().spaced_points(3).unwrap()
  inspect(values.length() == 3, content="true")
  inspect(values[0] == -1.0F, content="true")
  inspect(values[1] == 0.0F, content="true")
  inspect(values[2] == 1.0F, content="true")
}

///|
test "curve: function curve map and graph preserve domain" {
  let source = FunctionCurve::new(Interval::unit(), fn(t) { t * 2.0F })
  let mapped = source.to_curve().map(fn(value) { value + 1.0F })
  let graphed = mapped.graph()
  inspect(mapped.sample(0.25F).unwrap() == 1.5F, content="true")
  inspect(graphed.sample(0.5F).unwrap().0 == 0.5F, content="true")
  inspect(graphed.sample(0.5F).unwrap().1 == 2.0F, content="true")
}

///|
test "curve: sample auto curve interpolates stable values" {
  let curve = SampleAutoCurve::new(Interval::unit(), [0.0F, 10.0F]).unwrap()
  inspect(curve.sample(0.5F).unwrap() == 5.0F, content="true")
}

///|
test "curve: cubic curve adapters expose derivative carriers" {
  let segment = CubicSegment::new_bezier(0.0F, 1.0F, 2.0F, 3.0F)
  let sample = segment.sample_with_two_derivatives(0.5F)
  inspect(sample.value > 0.0F, content="true")
  inspect(sample.derivative > 0.0F, content="true")
}
