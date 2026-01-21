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
pub struct HashMap {
  entries : Array[(Int, String)]
}

///|
pub fn HashMap::from_array(items : Array[(Int, String)]) -> HashMap {
  let entries : Array[(Int, String)] = []
  for item in items {
    entries.push(item)
  }
  HashMap::{ entries, }
}

///|
pub fn HashMap::equals(self : HashMap, other : HashMap) -> Bool {
  if self.entries.length() != other.entries.length() {
    return false
  }
  for item in self.entries {
    let mut found = false
    for other_item in other.entries {
      if item.0 == other_item.0 && item.1 == other_item.1 {
        found = true
        break
      }
    }
    if !found {
      return false
    }
  }
  true
}

///|
fn write_json_string(sb : StringBuilder, value : String) -> Unit {
  for c in value {
    match c {
      '\\' => sb.write_string("\\\\")
      '"' => sb.write_string("\\\"")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(c)
    }
  }
}

///|
pub fn serialize_to_vec_tuple(target : HashMap) -> String {
  let sb = StringBuilder::new()
  sb.write_string("{\"map\":[")
  for i in 0..<target.entries.length() {
    if i > 0 {
      sb.write_char(',')
    }
    let entry = target.entries[i]
    sb.write_char('[')
    sb.write_object(entry.0)
    sb.write_string(",\"")
    write_json_string(sb, entry.1)
    sb.write_string("\"]")
  }
  sb.write_string("]}")
  sb.to_string()
}

///|
fn split_values(text : String, sep : String) -> Array[String] {
  let values : Array[String] = []
  for part in text.split(sep[:]) {
    let value = part.to_string()
    if value.length() > 0 {
      values.push(value)
    }
  }
  values
}

///|
fn parse_int_value(text : String) -> Int {
  let mut sign = 1
  let mut value = 0
  let mut started = false
  for c in text {
    if !started && c == '-' {
      sign = -1
      started = true
    } else if c >= '0' && c <= '9' {
      value = value * 10 + (c.to_int() - '0'.to_int())
      started = true
    }
  }
  sign * value
}

///|
fn unescape_json_string(text : String) -> String {
  let sb = StringBuilder::new()
  let mut escaped = false
  for c in text {
    if escaped {
      let mapped = match c {
        'n' => '\n'
        'r' => '\r'
        't' => '\t'
        '"' => '"'
        '\\' => '\\'
        _ => c
      }
      sb.write_char(mapped)
      escaped = false
    } else if c == '\\' {
      escaped = true
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
pub fn deserialize_from_vec_tuple(value : String) -> HashMap {
  let entries : Array[(Int, String)] = []
  if value.strip_prefix("{\"map\":["[:]) is Some(list_view) {
    if list_view.strip_suffix("]}"[:]) is Some(items_view) {
      let items = items_view.to_string()
      if items.length() > 0 {
        for part in items.split("],["[:]) {
          let mut entry_view = part
          if entry_view.strip_prefix("["[:]) is Some(view) {
            entry_view = view
          }
          if entry_view.strip_suffix("]"[:]) is Some(view) {
            entry_view = view
          }
          let fields = split_values(entry_view.to_string(), ",")
          if fields.length() >= 2 {
            let key = parse_int_value(fields[0])
            let mut raw_text = fields[1]
            if raw_text.strip_prefix("\""[:]) is Some(view) {
              raw_text = view.to_string()
            }
            if raw_text.strip_suffix("\""[:]) is Some(view) {
              raw_text = view.to_string()
            }
            let parsed = unescape_json_string(raw_text)
            entries.push((key, parsed))
          }
        }
      }
    }
  }
  HashMap::{ entries, }
}
