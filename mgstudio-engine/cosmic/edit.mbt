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
/// Editing primitives (ported from `cosmic-text/src/edit/mod.rs`).

///|
/// An action to perform on an editor.
pub(all) enum Action {
  Motion(Motion)
  Escape
  Insert(Char)
  Enter
  Backspace
  Delete
  Indent
  Unindent
  Click(Int, Int)
  DoubleClick(Int, Int)
  TripleClick(Int, Int)
  Drag(Int, Int)
  Scroll(Float)
}

///|
/// Selection mode.
pub(all) enum Selection {
  None
  Normal(Cursor)
  Line(Cursor)
  Word(Cursor)
}

///|
pub impl Eq for Selection with equal(self, other) {
  match (self, other) {
    (None, None) => true
    (Normal(a), Normal(b)) => a == b
    (Line(a), Line(b)) => a == b
    (Word(a), Word(b)) => a == b
    _ => false
  }
}

///|
/// A unique change to an editor.
pub(all) struct ChangeItem {
  start : Cursor
  end : Cursor
  text : String
  insert : Bool
}

///|
pub fn ChangeItem::reverse(self : ChangeItem) -> ChangeItem {
  ChangeItem::{ ..self, insert: !self.insert }
}

///|
/// A set of change items grouped into one logical change.
pub(all) struct Change {
  items : Array[ChangeItem]
}

///|
pub fn Change::default() -> Change {
  Change::{ items: [] }
}

///|
pub fn Change::reverse(self : Change) -> Change {
  let items : Array[ChangeItem] = []
  // Reverse order and flip insert/delete.
  let mut i = self.items.length() - 1
  while i >= 0 {
    items.push(self.items[i].reverse())
    if i == 0 {
      break
    }
    i = i - 1
  }
  Change::{ items, }
}
