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
test "messages: reader returns only messages in system tick range" {
  let messages = Messages::new()
  messages.send(3, "three")
  messages.send(4, "four")

  let r0 = messages.reader(SystemTicks::new(0, 2)).read()
  inspect(r0.length(), content="0")

  let r1 = messages.reader(SystemTicks::new(2, 3)).read()
  inspect(r1.length(), content="1")
  inspect(r1[0] == "three", content="true")

  let r2 = messages.reader(SystemTicks::new(3, 4)).read()
  inspect(r2.length(), content="1")
  inspect(r2[0] == "four", content="true")
}

///|
test "messages: keeps current and previous ticks only" {
  let messages = Messages::new()
  messages.send(1, "a")
  messages.send(2, "b")
  messages.send(3, "c")

  let r = messages.reader(SystemTicks::new(0, 3)).read()
  inspect(r.length(), content="2")
  inspect(r[0] == "b", content="true")
  inspect(r[1] == "c", content="true")
}

///|
test "messages: clear resets history" {
  let messages = Messages::new()
  messages.send(1, "a")
  messages.send(2, "b")
  messages.clear()
  let r = messages.reader(SystemTicks::new(0, 10)).read()
  inspect(r.length(), content="0")
}

///|
test "messages: reader.read is consuming" {
  let messages = Messages::new()
  messages.send(2, "a")
  let reader = messages.reader(SystemTicks::new(0, 2))
  let first = reader.read()
  inspect(first.length(), content="1")
  inspect(first[0] == "a", content="true")
  let second = reader.read()
  inspect(second.length(), content="0")
}

///|
test "messages: writer appends at writer tick" {
  let messages = Messages::new()
  let writer = messages.writer(5)
  writer.write("value")
  let read = messages.reader(SystemTicks::new(0, 5)).read()
  inspect(read.length(), content="1")
  inspect(read[0] == "value", content="true")
}

///|
test "messages: writer.write_batch appends all messages at writer tick" {
  let messages = Messages::new()
  let writer = messages.writer(7)
  writer.write_batch(["first", "second", "third"])
  let read = messages.reader(SystemTicks::new(0, 7)).read()
  inspect(read.length(), content="3")
  inspect(read[0] == "first", content="true")
  inspect(read[1] == "second", content="true")
  inspect(read[2] == "third", content="true")
}
