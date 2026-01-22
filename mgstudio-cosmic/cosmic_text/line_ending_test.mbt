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

test "LineIter (upstream test vector)" {
  let string = "LF\nCRLF\r\nCR\rLFCR\n\rNONE"
  let iter0 = LineIter::new(string)
  let (iter1, r1) = iter0.next()
  inspect(r1.map(v => v.0), content="Some(0)")
  inspect(r1.map(v => v.1), content="Some(2)")
  inspect(r1.map(v => match v.2 { Lf => true; _ => false }), content="Some(true)")
  let (iter2, r2) = iter1.next()
  inspect(r2.map(v => v.0), content="Some(3)")
  inspect(r2.map(v => v.1), content="Some(7)")
  inspect(r2.map(v => match v.2 { CrLf => true; _ => false }), content="Some(true)")
  let (iter3, r3) = iter2.next()
  inspect(r3.map(v => v.0), content="Some(9)")
  inspect(r3.map(v => v.1), content="Some(11)")
  inspect(r3.map(v => match v.2 { Cr => true; _ => false }), content="Some(true)")
  let (iter4, r4) = iter3.next()
  inspect(r4.map(v => v.0), content="Some(12)")
  inspect(r4.map(v => v.1), content="Some(16)")
  inspect(r4.map(v => match v.2 { LfCr => true; _ => false }), content="Some(true)")
  let (iter5, r5) = iter4.next()
  inspect(r5.map(v => v.0), content="Some(18)")
  inspect(r5.map(v => v.1), content="Some(22)")
  inspect(r5.map(v => match v.2 { None => true; _ => false }), content="Some(true)")
  let (_, r6) = iter5.next()
  inspect(match r6 { None => true; _ => false }, content="true")
}
