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
/// SVG path data parser.
///
/// Ported from upstream `zeno/src/svg_parser.rs` (Apache-2.0 OR MIT).
enum State {
  Initial
  Next
  Continue(Int)
}

///|
pub struct SvgCommands {
  source : String
  mut cur : Int
  mut pos : Int
  mut cmd_pos : Int
  mut error : Bool
  mut done : Bool
  mut start_point : Vector
  mut cur_point : Vector
  mut last_control : Vector
  mut last_cmd : Int
  mut state : State
  mut arc : Arc
}

///|
pub fn SvgCommands::new(source : String) -> SvgCommands {
  SvgCommands::{
    source,
    cur: 0,
    pos: 0,
    cmd_pos: 0,
    error: false,
    done: false,
    start_point: Vector::zero(),
    cur_point: Vector::zero(),
    last_control: Vector::zero(),
    last_cmd: 0,
    state: State::Initial,
    arc: Arc::default(),
  }
}

///|
pub fn SvgCommands::next(self : SvgCommands) -> Command? {
  self.parse()
}

///|
fn SvgCommands::parse(self : SvgCommands) -> Command? {
  let mut cmd = self.cur
  while true {
    if self.arc.next() is Some(arc_cmd) {
      return Some(arc_cmd)
    }
    self.last_cmd = cmd
    match self.state {
      State::Initial => {
        self.advance()
        self.skip_whitespace()
        self.state = State::Next
        continue
      }
      State::Next => {
        self.skip_whitespace()
        self.cmd_pos = self.pos
        cmd = self.cur
        self.advance()
        self.skip_whitespace()
        self.state = State::Continue(cmd)
        match cmd {
          122 => {
            self.state = State::Next
            self.cur_point = self.start_point
            return Some(Command::Close)
          }
          90 => {
            self.state = State::Next
            self.cur_point = self.start_point
            return Some(Command::Close)
          }
          77 =>
            match self.point_to() {
              Some(to) => {
                self.start_point = to
                self.skip_comma_whitespace()
                return Some(Command::MoveTo(to))
              }
              None => return None
            }
          109 =>
            match self.rel_point_to() {
              Some(to) => {
                self.start_point = to
                self.skip_comma_whitespace()
                return Some(Command::MoveTo(to))
              }
              None => return None
            }
          76 =>
            match self.point_to() {
              Some(to) => {
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => return None
            }
          108 =>
            match self.rel_point_to() {
              Some(to) => {
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => return None
            }
          72 =>
            match self.coord() {
              Some(x) => {
                let to = Vector::new(x, self.cur_point.y())
                self.cur_point = to
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => return None
            }
          104 =>
            match self.coord() {
              Some(x) => {
                let to = Vector::new(self.cur_point.x() + x, self.cur_point.y())
                self.cur_point = to
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => return None
            }
          86 =>
            match self.coord() {
              Some(y) => {
                let to = Vector::new(self.cur_point.x(), y)
                self.cur_point = to
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => return None
            }
          118 =>
            match self.coord() {
              Some(y) => {
                let to = Vector::new(self.cur_point.x(), self.cur_point.y() + y)
                self.cur_point = to
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => return None
            }
          67 =>
            match self.three_points_to() {
              Some((c1, c2, to)) => {
                self.last_control = c2
                self.skip_comma_whitespace()
                return Some(Command::CurveTo(c1, c2, to))
              }
              None => return None
            }
          99 =>
            match self.rel_three_points_to() {
              Some((c1, c2, to)) => {
                self.last_control = c2
                self.skip_comma_whitespace()
                return Some(Command::CurveTo(c1, c2, to))
              }
              None => return None
            }
          83 =>
            match self.two_points() {
              Some((c2, to)) => {
                let c1 = self.reflected_control(cmd)
                self.cur_point = to
                self.last_control = c2
                self.skip_comma_whitespace()
                return Some(Command::CurveTo(c1, c2, to))
              }
              None => return None
            }
          115 =>
            match self.rel_two_points() {
              Some((c2, to)) => {
                let c1 = self.reflected_control(cmd)
                self.cur_point = to
                self.last_control = c2
                self.skip_comma_whitespace()
                return Some(Command::CurveTo(c1, c2, to))
              }
              None => return None
            }
          81 =>
            match self.two_points_to() {
              Some((c, to)) => {
                self.last_control = c
                self.skip_comma_whitespace()
                return Some(Command::QuadTo(c, to))
              }
              None => return None
            }
          113 =>
            match self.rel_two_points_to() {
              Some((c, to)) => {
                self.last_control = c
                self.skip_comma_whitespace()
                return Some(Command::QuadTo(c, to))
              }
              None => return None
            }
          84 =>
            match self.point() {
              Some(to) => {
                let c = self.reflected_control(cmd)
                self.cur_point = to
                self.last_control = c
                self.skip_comma_whitespace()
                return Some(Command::QuadTo(c, to))
              }
              None => return None
            }
          116 =>
            match self.rel_point() {
              Some(to) => {
                let c = self.reflected_control(cmd)
                self.cur_point = to
                self.last_control = c
                self.skip_comma_whitespace()
                return Some(Command::QuadTo(c, to))
              }
              None => return None
            }
          65 => {
            let from = self.cur_point
            match self.arc_arguments(false) {
              Some((rx, ry, a, size, sweep, to)) => {
                self.arc = Arc::new(
                  from,
                  rx,
                  ry,
                  to_radians(a),
                  size,
                  sweep,
                  to,
                )
                self.skip_comma_whitespace()
                continue
              }
              None => return None
            }
          }
          97 => {
            let from = self.cur_point
            match self.arc_arguments(true) {
              Some((rx, ry, a, size, sweep, to)) => {
                self.arc = Arc::new(
                  from,
                  rx,
                  ry,
                  to_radians(a),
                  size,
                  sweep,
                  to,
                )
                self.skip_comma_whitespace()
                continue
              }
              None => return None
            }
          }
          _ => {
            if !self.done || cmd != 0 {
              self.error = true
              self.pos = self.cmd_pos
            }
            return None
          }
        }
      }
      State::Continue(cmd0) =>
        match cmd0 {
          77 =>
            match self.point_to() {
              Some(to) => {
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          109 =>
            match self.rel_point_to() {
              Some(to) => {
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          76 =>
            match self.point_to() {
              Some(to) => {
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          108 =>
            match self.rel_point_to() {
              Some(to) => {
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          72 =>
            match self.coord() {
              Some(x) => {
                let to = Vector::new(x, self.cur_point.y())
                self.cur_point = to
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          104 =>
            match self.coord() {
              Some(x) => {
                let to = Vector::new(self.cur_point.x() + x, self.cur_point.y())
                self.cur_point = to
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          86 =>
            match self.coord() {
              Some(y) => {
                let to = Vector::new(self.cur_point.x(), y)
                self.cur_point = to
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          118 =>
            match self.coord() {
              Some(y) => {
                let to = Vector::new(self.cur_point.x(), self.cur_point.y() + y)
                self.cur_point = to
                self.skip_comma_whitespace()
                return Some(Command::LineTo(to))
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          67 =>
            match self.point() {
              Some(c1) => {
                self.skip_comma_whitespace()
                match self.two_points_to() {
                  Some((c2, to)) => {
                    self.last_control = c2
                    self.skip_comma_whitespace()
                    return Some(Command::CurveTo(c1, c2, to))
                  }
                  None => return None
                }
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          99 =>
            match self.rel_point() {
              Some(c1) => {
                self.skip_comma_whitespace()
                match self.rel_two_points_to() {
                  Some((c2, to)) => {
                    self.last_control = c2
                    self.skip_comma_whitespace()
                    return Some(Command::CurveTo(c1, c2, to))
                  }
                  None => return None
                }
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          83 =>
            match self.point() {
              Some(c2) => {
                self.skip_comma_whitespace()
                match self.point() {
                  Some(to) => {
                    let c1 = self.reflected_control(cmd0)
                    self.cur_point = to
                    self.last_control = c2
                    self.skip_comma_whitespace()
                    return Some(Command::CurveTo(c1, c2, to))
                  }
                  None => return None
                }
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          115 =>
            match self.rel_point() {
              Some(c2) => {
                self.skip_comma_whitespace()
                match self.rel_point() {
                  Some(to) => {
                    let c1 = self.reflected_control(cmd0)
                    self.cur_point = to
                    self.last_control = c2
                    self.skip_comma_whitespace()
                    return Some(Command::CurveTo(c1, c2, to))
                  }
                  None => return None
                }
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          81 =>
            match self.point() {
              Some(c) => {
                self.last_control = c
                self.skip_comma_whitespace()
                match self.point_to() {
                  Some(to) => {
                    self.skip_comma_whitespace()
                    return Some(Command::QuadTo(c, to))
                  }
                  None => return None
                }
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          113 =>
            match self.rel_point() {
              Some(c) => {
                self.last_control = c
                self.skip_comma_whitespace()
                match self.rel_point_to() {
                  Some(to) => {
                    self.skip_comma_whitespace()
                    return Some(Command::QuadTo(c, to))
                  }
                  None => return None
                }
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          84 =>
            match self.point() {
              Some(to) => {
                let c = self.reflected_control(cmd0)
                self.cur_point = to
                self.last_control = c
                self.skip_comma_whitespace()
                return Some(Command::QuadTo(c, to))
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          116 =>
            match self.rel_point() {
              Some(to) => {
                let c = self.reflected_control(cmd0)
                self.cur_point = to
                self.last_control = c
                self.skip_comma_whitespace()
                return Some(Command::QuadTo(c, to))
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          65 =>
            match self.coord() {
              Some(rx) => {
                let from = self.cur_point
                match self.arc_rest_arguments(false) {
                  Some((ry, a, size, sweep, to)) => {
                    self.arc = Arc::new(
                      from,
                      rx,
                      ry,
                      to_radians(a),
                      size,
                      sweep,
                      to,
                    )
                    self.skip_comma_whitespace()
                    continue
                  }
                  None => return None
                }
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          97 =>
            match self.coord() {
              Some(rx) => {
                let from = self.cur_point
                match self.arc_rest_arguments(true) {
                  Some((ry, a, size, sweep, to)) => {
                    self.arc = Arc::new(
                      from,
                      rx,
                      ry,
                      to_radians(a),
                      size,
                      sweep,
                      to,
                    )
                    self.skip_comma_whitespace()
                    continue
                  }
                  None => return None
                }
              }
              None => {
                self.state = State::Next
                continue
              }
            }
          _ => {
            if !self.done || cmd0 != 0 {
              self.error = true
              self.pos = self.cmd_pos
            }
            return None
          }
        }
    }
  } else {
    None
  }
}

///|
fn to_radians(deg : Double) -> Double {
  deg * (@coremath.PI / 180.0)
}

///|
fn SvgCommands::reflected_control(self : SvgCommands, cmd : Int) -> Vector {
  let cur = self.cur_point
  let old = self.last_control
  if cmd == 83 || cmd == 115 {
    match self.last_cmd {
      67 | 99 | 83 | 115 =>
        Vector::new(2.0 * cur.x() - old.x(), 2.0 * cur.y() - old.y())
      _ => self.cur_point
    }
  } else {
    match self.last_cmd {
      81 | 113 | 84 | 116 =>
        Vector::new(2.0 * cur.x() - old.x(), 2.0 * cur.y() - old.y())
      _ => self.cur_point
    }
  }
}

///|
fn SvgCommands::arc_arguments(
  self : SvgCommands,
  rel : Bool,
) -> (Double, Double, Double, ArcSize, ArcSweep, Vector)? {
  match self.coord() {
    Some(rx) => {
      self.skip_comma_whitespace()
      match self.coord() {
        Some(ry) => {
          self.skip_comma_whitespace()
          match self.coord() {
            Some(a) => {
              self.skip_comma_whitespace()
              match self.boolean() {
                Some(large_arc) => {
                  self.skip_comma_whitespace()
                  match self.boolean() {
                    Some(sweep) => {
                      self.skip_comma_whitespace()
                      let to = if rel {
                        self.rel_point_to()
                      } else {
                        self.point_to()
                      }
                      match to {
                        Some(to0) => {
                          let size = if large_arc {
                            ArcSize::Large
                          } else {
                            ArcSize::Small
                          }
                          let sweep2 = if sweep {
                            ArcSweep::Positive
                          } else {
                            ArcSweep::Negative
                          }
                          Some((rx, ry, a, size, sweep2, to0))
                        }
                        None => None
                      }
                    }
                    None => None
                  }
                }
                None => None
              }
            }
            None => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn SvgCommands::arc_rest_arguments(
  self : SvgCommands,
  rel : Bool,
) -> (Double, Double, ArcSize, ArcSweep, Vector)? {
  match self.coord() {
    Some(ry) => {
      self.skip_comma_whitespace()
      match self.coord() {
        Some(a) => {
          self.skip_comma_whitespace()
          match self.boolean() {
            Some(large_arc) => {
              self.skip_comma_whitespace()
              match self.boolean() {
                Some(sweep) => {
                  self.skip_comma_whitespace()
                  let to = if rel {
                    self.rel_point_to()
                  } else {
                    self.point_to()
                  }
                  match to {
                    Some(to0) => {
                      let size = if large_arc {
                        ArcSize::Large
                      } else {
                        ArcSize::Small
                      }
                      let sweep2 = if sweep {
                        ArcSweep::Positive
                      } else {
                        ArcSweep::Negative
                      }
                      Some((ry, a, size, sweep2, to0))
                    }
                    None => None
                  }
                }
                None => None
              }
            }
            None => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn SvgCommands::point(self : SvgCommands) -> Vector? {
  match self.coord() {
    Some(a) => {
      self.skip_comma_whitespace()
      match self.coord() {
        Some(b) => Some(Vector::new(a, b))
        None => None
      }
    }
    None => None
  }
}

///|
fn SvgCommands::point_to(self : SvgCommands) -> Vector? {
  match self.point() {
    Some(p) => {
      self.cur_point = p
      Some(p)
    }
    None => None
  }
}

///|
fn SvgCommands::rel_point(self : SvgCommands) -> Vector? {
  match self.point() {
    Some(p) =>
      Some(Vector::new(p.x() + self.cur_point.x(), p.y() + self.cur_point.y()))
    None => None
  }
}

///|
fn SvgCommands::rel_point_to(self : SvgCommands) -> Vector? {
  match self.rel_point() {
    Some(p) => {
      self.cur_point = p
      Some(p)
    }
    None => None
  }
}

///|
fn SvgCommands::two_points_to(self : SvgCommands) -> (Vector, Vector)? {
  match self.point() {
    Some(a) => {
      self.skip_comma_whitespace()
      match self.point_to() {
        Some(b) => Some((a, b))
        None => None
      }
    }
    None => None
  }
}

///|
fn SvgCommands::two_points(self : SvgCommands) -> (Vector, Vector)? {
  match self.point() {
    Some(a) => {
      self.skip_comma_whitespace()
      match self.point() {
        Some(b) => Some((a, b))
        None => None
      }
    }
    None => None
  }
}

///|
fn SvgCommands::rel_two_points_to(self : SvgCommands) -> (Vector, Vector)? {
  match self.rel_point() {
    Some(a) => {
      self.skip_comma_whitespace()
      match self.rel_point_to() {
        Some(b) => Some((a, b))
        None => None
      }
    }
    None => None
  }
}

///|
fn SvgCommands::rel_two_points(self : SvgCommands) -> (Vector, Vector)? {
  match self.rel_point() {
    Some(a) => {
      self.skip_comma_whitespace()
      match self.rel_point() {
        Some(b) => Some((a, b))
        None => None
      }
    }
    None => None
  }
}

///|
fn SvgCommands::three_points_to(
  self : SvgCommands,
) -> (Vector, Vector, Vector)? {
  match self.point() {
    Some(a) => {
      self.skip_comma_whitespace()
      match self.point() {
        Some(b) => {
          self.skip_comma_whitespace()
          match self.point_to() {
            Some(c) => Some((a, b, c))
            None => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn SvgCommands::rel_three_points_to(
  self : SvgCommands,
) -> (Vector, Vector, Vector)? {
  match self.rel_point() {
    Some(a) => {
      self.skip_comma_whitespace()
      match self.rel_point() {
        Some(b) => {
          self.skip_comma_whitespace()
          match self.rel_point_to() {
            Some(c) => Some((a, b, c))
            None => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn SvgCommands::coord(self : SvgCommands) -> Double? {
  match self.cur {
    43 => {
      self.advance()
      self.number()
    }
    45 => {
      self.advance()
      match self.number() {
        Some(n) => Some(-n)
        None => None
      }
    }
    _ => self.number()
  }
}

///|
fn SvgCommands::number(self : SvgCommands) -> Double? {
  let mut value = 0.0
  let mut has_digit = false
  while self.cur >= 48 && self.cur <= 57 {
    value = value * 10.0 + (self.cur - 48).to_double()
    has_digit = true
    self.advance()
  }
  if self.cur == 46 {
    self.advance()
    let mut scale = 1.0
    while self.cur >= 48 && self.cur <= 57 {
      scale = scale * 0.1
      value = value + (self.cur - 48).to_double() * scale
      has_digit = true
      self.advance()
    }
  }
  if has_digit {
    Some(value)
  } else {
    None
  }
}

///|
fn SvgCommands::boolean(self : SvgCommands) -> Bool? {
  match self.cur {
    48 => {
      self.advance()
      Some(false)
    }
    49 => {
      self.advance()
      Some(true)
    }
    _ => None
  }
}

///|
fn SvgCommands::skip_comma_whitespace(self : SvgCommands) -> Unit {
  self.skip_whitespace()
  if self.accept(44) {
    self.skip_whitespace()
  }
}

///|
fn SvgCommands::skip_whitespace(self : SvgCommands) -> Unit {
  while self.accept_by(fn(b) {
          match b {
            0x9 | 0x20 | 0xA | 0xC | 0xD => true
            _ => false
          }
        }) {

  }
}

///|
fn SvgCommands::accept(self : SvgCommands, b : Int) -> Bool {
  if self.cur == b {
    self.advance()
    true
  } else {
    false
  }
}

///|
fn SvgCommands::accept_by(self : SvgCommands, f : (Int) -> Bool) -> Bool {
  if f(self.cur) {
    self.advance()
    true
  } else {
    false
  }
}

///|
fn SvgCommands::advance(self : SvgCommands) -> Unit {
  if self.pos >= self.source.length() {
    self.done = true
    self.cur = 0
    return
  }
  self.cur = self.source.code_unit_at(self.pos).to_int()
  self.pos = self.pos + 1
}

///|
/// Validate an SVG path string and return the first invalid position.
pub fn validate_svg(svg : String) -> Result[Unit, Int] {
  let cmds = SvgCommands::new(svg)
  let it = Iter::new(fn() { cmds.next() })
  while it.next() is Some(_cmd) {

  }
  let pos = cmds.pos
  if cmds.error || pos != svg.length() {
    let p = if pos > 0 { pos - 1 } else { 0 }
    Err(p)
  } else {
    Ok(())
  }
}
