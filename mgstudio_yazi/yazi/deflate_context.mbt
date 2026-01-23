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
/// Streaming DEFLATE encoder core.
///
/// Ported from `yazi/src/encode.rs` (Apache-2.0 OR MIT).

// ---- Constants -------------------------------------------------------------

const ENC_LITERAL_LENGTH_TREE_SIZE : Int = 288

///|
const ENC_DISTANCE_TREE_SIZE : Int = 32

///|
const ENC_PRECODE_TREE_SIZE : Int = 19

///|
const ENC_CODE_BUFFER_SIZE : Int = 64 * 1024

///|
const ENC_HASH_BITS : Int = 15

///|
const ENC_HASH_SHIFT : Int = (ENC_HASH_BITS + 2) / 3

///|
const ENC_HASH_SIZE : Int = 1 << ENC_HASH_BITS

///|
const ENC_MIN_MATCH_LEN : Int = 3

///|
const ENC_MAX_MATCH_LEN : Int = 258

///|
const ENC_DICTIONARY_SIZE : Int = 32768

///|
const ENC_DICTIONARY_SIZE_MASK : Int = ENC_DICTIONARY_SIZE - 1

///|
const ENC_DICTIONARY_FULL_SIZE : Int = ENC_DICTIONARY_SIZE + ENC_MAX_MATCH_LEN

///|
const ENC_WRITE_ZLIB_HEADER : UInt = 0x0000_1000

///|
const ENC_GREEDY_PARSING : UInt = 0x0000_4000

///|
const ENC_RLE_MATCHES : UInt = 0x0001_0000

///|
const ENC_FILTER_MATCHES : UInt = 0x0002_0000

///|
const ENC_FORCE_STATIC : UInt = 0x0004_0000

///|
const ENC_FORCE_RAW : UInt = 0x0008_0000

///|
const ENC_MAX_PROBES_MASK : UInt = 0xFFF

///|
fn enc_num_probes(level : Int) -> Int {
  match level {
    0 => 0
    1 => 1
    2 => 6
    3 => 32
    4 => 16
    5 => 32
    6 => 128
    7 => 256
    8 => 512
    9 => 768
    _ => 1500
  }
}

// ---- Flags ----------------------------------------------------------------

///|
fn level_to_raw(level : CompressionLevel) -> Int {
  match level {
    NoCompression => 0
    BestSpeed => 1
    Default => 6
    BestSize => 9
    Specific(n) => {
      let v = n.reinterpret_as_int()
      if v <= 0 {
        0
      } else if v > 10 {
        10
      } else {
        v
      }
    }
  }
}

///|
fn enc_make_flags(
  zlib : Bool,
  level : CompressionLevel,
  strategy : CompressionStrategy,
) -> UInt {
  let lv = level_to_raw(level)
  let greedy = if lv <= 3 { ENC_GREEDY_PARSING } else { 0 }
  let mut flags = enc_num_probes(lv).reinterpret_as_uint() | greedy
  if zlib {
    flags = flags | ENC_WRITE_ZLIB_HEADER
  }
  if lv == 0 {
    flags = flags | ENC_FORCE_RAW
  } else {
    match strategy {
      Filtered => flags = flags | ENC_FILTER_MATCHES
      // Clear the lower 12 bits that store NUM_PROBES.
      Huffman => flags = flags & 0xFFFF_F000
      Static => flags = flags | ENC_FORCE_STATIC
      RLE => flags = flags | ENC_RLE_MATCHES
      _ => ()
    }
  }
  flags
}

///|
fn enc_make_zlib_header(flags : UInt) -> (UInt, UInt) {
  // Returns two bytes (CMF, FLG).
  let fcheck_divisor : UInt = 31
  let num_probes = flags & ENC_MAX_PROBES_MASK
  let level = if (flags & ENC_GREEDY_PARSING) != 0 {
    if num_probes <= 1 {
      0
    } else {
      1
    }
  } else if num_probes >= enc_num_probes(9).reinterpret_as_uint() {
    3
  } else {
    2
  }
  let cmf : UInt = 8 | (7 << 4)
  let flg : UInt = level.reinterpret_as_uint() << 6
  let rem = (cmf * 256 + flg) % fcheck_divisor
  let check = (flg & 0b1110_0000) + (fcheck_divisor - rem)
  (cmf, check)
}

// ---- Huffman ---------------------------------------------------------------

///|
priv struct SymbolFrequency {
  mut key : UInt
  index : UInt
}

///|
fn sym_default() -> SymbolFrequency {
  SymbolFrequency::{ key: 0, index: 0 }
}

///|
fn huffman_optimize(
  counts : Array[UInt],
  codes : Array[UInt],
  code_sizes : Array[Int],
  size_limit : Int,
  is_static : Bool,
) -> Unit {
  let max_supported_huff_code_size : Int = 32
  let num_codes : Array[Int] = []
  let next_code : Array[UInt] = []
  for _ in 0..<(1 + max_supported_huff_code_size) {
    num_codes.push(0)
    next_code.push(0)
  }
  let len = counts.length()
  if is_static {
    for i in 0..<len {
      num_codes[code_sizes[i]] = num_codes[code_sizes[i]] + 1
    }
  } else {
    // Collect used symbols.
    let syms0 : Array[SymbolFrequency] = []
    for i in 0..<len {
      let c = counts[i]
      if c != 0 {
        syms0.push(SymbolFrequency::{ key: c, index: i.reinterpret_as_uint() })
      }
    }
    // Radix sort by key (u16 in upstream).
    let syms = sort_symbols(syms0)
    minimum_redundancy(syms)
    for s in syms {
      num_codes[s.key.reinterpret_as_int()] = num_codes[s.key.reinterpret_as_int()] +
        1
    }
    enforce_size_limit(num_codes, syms.length(), size_limit)
    for i in 0..<len {
      codes[i] = 0
      code_sizes[i] = 0
    }
    let mut last = syms.length()
    for i in 1..<(size_limit + 1) {
      let first = last - num_codes[i]
      for j in first..<last {
        let idx = syms[j].index.reinterpret_as_int()
        code_sizes[idx] = i
      }
      last = first
    }
  }
  next_code[1] = 0
  let mut j = 0
  for i in 2..<(size_limit + 1) {
    j = (j + num_codes[i - 1]) << 1
    next_code[i] = j.reinterpret_as_uint()
  }
  for i in 0..<len {
    let code_size = code_sizes[i]
    if code_size == 0 {
      continue
    }
    let mut code = next_code[code_size]
    next_code[code_size] = next_code[code_size] + 1
    let mut rev : UInt = 0
    for _ in 0..<code_size {
      rev = (rev << 1) | (code & 1)
      code = code >> 1
    }
    codes[i] = rev
  }
}

///|
fn sort_symbols(syms0 : Array[SymbolFrequency]) -> Array[SymbolFrequency] {
  let hist0 : Array[Int] = []
  let hist1 : Array[Int] = []
  for _ in 0..<256 {
    hist0.push(0)
    hist1.push(0)
  }
  for s in syms0 {
    let key = s.key.reinterpret_as_int()
    hist0[key & 0xFF] = hist0[key & 0xFF] + 1
    hist1[(key >> 8) & 0xFF] = hist1[(key >> 8) & 0xFF] + 1
  }
  let mut passes = 2
  if syms0.length() == hist1[0] {
    passes = 1
  }
  let mut cur = syms0
  let mut tmp : Array[SymbolFrequency] = []
  for _ in 0..<cur.length() {
    tmp.push(sym_default())
  }
  for pass in 0..<passes {
    let offsets : Array[Int] = []
    for _ in 0..<256 {
      offsets.push(0)
    }
    let mut off = 0
    for i in 0..<256 {
      offsets[i] = off
      let inc = if pass == 0 { hist0[i] } else { hist1[i] }
      off = off + inc
    }
    for s in cur {
      let j = ((s.key >> (pass * 8)) & 0xFF).reinterpret_as_int()
      tmp[offsets[j]] = s
      offsets[j] = offsets[j] + 1
    }
    cur = tmp
    tmp = []
    for _ in 0..<cur.length() {
      tmp.push(sym_default())
    }
  }
  cur
}

///|
fn minimum_redundancy(a : Array[SymbolFrequency]) -> Unit {
  let n = a.length()
  if n == 0 {
    return
  } else if n == 1 {
    a[0].key = 1
    return
  }
  a[0].key = a[0].key + a[1].key
  let mut root = 0
  let mut leaf = 2
  for next in 1..<(n - 1) {
    if leaf >= n || a[root].key < a[leaf].key {
      a[next].key = a[root].key
      a[root].key = next.reinterpret_as_uint()
      root = root + 1
    } else {
      a[next].key = a[leaf].key
      leaf = leaf + 1
    }
    if leaf >= n || (root < next && a[root].key < a[leaf].key) {
      a[next].key = a[next].key + a[root].key
      a[root].key = next.reinterpret_as_uint()
      root = root + 1
    } else {
      a[next].key = a[next].key + a[leaf].key
      leaf = leaf + 1
    }
  }
  a[n - 2].key = 0
  let mut next = n - 3
  while next >= 0 {
    a[next].key = a[a[next].key.reinterpret_as_int()].key + 1
    next = next - 1
  }
  let mut avail = 1
  let mut used = 0
  let mut depth = 0
  let mut root2 = n - 2
  let mut next2 = n - 1
  while avail > 0 {
    while root2 >= 0 && a[root2].key.reinterpret_as_int() == depth {
      used = used + 1
      root2 = root2 - 1
    }
    while avail > used {
      a[next2].key = depth.reinterpret_as_uint()
      next2 = next2 - 1
      avail = avail - 1
    }
    avail = 2 * used
    depth = depth + 1
    used = 0
  }
}

///|
fn enforce_size_limit(
  num_codes : Array[Int],
  len : Int,
  size_limit : Int,
) -> Unit {
  if len <= 1 {
    return
  }
  let max_supported_huff_code_size : Int = 32
  for i in (size_limit + 1)..<(max_supported_huff_code_size + 1) {
    num_codes[size_limit] = num_codes[size_limit] + num_codes[i]
  }
  let mut total : UInt = 0
  let mut i = size_limit
  while i >= 1 {
    total = total + (num_codes[i].reinterpret_as_uint() << (size_limit - i))
    i = i - 1
  }
  while total != (1 << size_limit).reinterpret_as_uint() {
    num_codes[size_limit] = num_codes[size_limit] - 1
    let mut j = size_limit - 1
    while j >= 1 {
      if num_codes[j] != 0 {
        num_codes[j] = num_codes[j] - 1
        num_codes[j + 1] = num_codes[j + 1] + 2
        break
      }
      j = j - 1
    }
    total = total - 1
  }
}

///|
priv struct EncLiteralLengthTree {
  counts : Array[UInt]
  codes : Array[UInt]
  code_sizes : Array[Int]
}

///|
fn EncLiteralLengthTree::new() -> EncLiteralLengthTree {
  let counts : Array[UInt] = []
  let codes : Array[UInt] = []
  let code_sizes : Array[Int] = []
  for _ in 0..<ENC_LITERAL_LENGTH_TREE_SIZE {
    counts.push(0)
    codes.push(0)
    code_sizes.push(0)
  }
  EncLiteralLengthTree::{ counts, codes, code_sizes }
}

///|
fn EncLiteralLengthTree::reset(self : EncLiteralLengthTree) -> Unit {
  for i in 0..<self.counts.length() {
    self.counts[i] = 0
  }
}

///|
fn EncLiteralLengthTree::optimize(
  self : EncLiteralLengthTree,
  is_static : Bool,
) -> Unit {
  huffman_optimize(self.counts, self.codes, self.code_sizes, 15, is_static)
}

///|
priv struct EncDistanceTree {
  counts : Array[UInt]
  codes : Array[UInt]
  code_sizes : Array[Int]
}

///|
fn EncDistanceTree::new() -> EncDistanceTree {
  let counts : Array[UInt] = []
  let codes : Array[UInt] = []
  let code_sizes : Array[Int] = []
  for _ in 0..<ENC_DISTANCE_TREE_SIZE {
    counts.push(0)
    codes.push(0)
    code_sizes.push(0)
  }
  EncDistanceTree::{ counts, codes, code_sizes }
}

///|
fn EncDistanceTree::reset(self : EncDistanceTree) -> Unit {
  for i in 0..<self.counts.length() {
    self.counts[i] = 0
  }
}

///|
fn EncDistanceTree::optimize(self : EncDistanceTree, is_static : Bool) -> Unit {
  huffman_optimize(self.counts, self.codes, self.code_sizes, 15, is_static)
}

///|
priv struct EncPrecodeTree {
  counts : Array[UInt]
  codes : Array[UInt]
  code_sizes : Array[Int]
}

///|
fn EncPrecodeTree::new() -> EncPrecodeTree {
  let counts : Array[UInt] = []
  let codes : Array[UInt] = []
  let code_sizes : Array[Int] = []
  for _ in 0..<ENC_PRECODE_TREE_SIZE {
    counts.push(0)
    codes.push(0)
    code_sizes.push(0)
  }
  EncPrecodeTree::{ counts, codes, code_sizes }
}

///|
fn EncPrecodeTree::reset(self : EncPrecodeTree) -> Unit {
  for i in 0..<self.counts.length() {
    self.counts[i] = 0
  }
}

///|
fn EncPrecodeTree::optimize(self : EncPrecodeTree) -> Unit {
  huffman_optimize(self.counts, self.codes, self.code_sizes, 7, false)
}

// ---- Length/Distance code helpers -----------------------------------------

///|
fn enc_len_info(len : Int) -> (Int, UInt, Int) {
  // Returns (sym, extra, extra_bits).
  // RFC1951 Table 3, length codes 257..285.
  let bases = [
    3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67,
    83, 99, 115, 131, 163, 195, 227, 258,
  ]
  let extra = [
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5,
    5, 5, 0,
  ]
  for i in 0..<bases.length() {
    let base = bases[i]
    let eb = extra[i]
    let max = base + ((1 << eb) - 1)
    if len <= max {
      return (257 + i, (len - base).reinterpret_as_uint(), eb)
    }
  }
  (285, 0, 0)
}

///|
fn enc_dist_info(dist : Int) -> (Int, UInt, Int) {
  // Returns (sym, extra, extra_bits).
  // RFC1951 Table 4, distance codes 0..29.
  let bases = [
    1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
    1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
  ]
  let extra = [
    0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11,
    11, 12, 12, 13, 13,
  ]
  for i in 0..<bases.length() {
    let base = bases[i]
    let eb = extra[i]
    let max = base + ((1 << eb) - 1)
    if dist <= max {
      return (i, (dist - base).reinterpret_as_uint(), eb)
    }
  }
  (0, 0, 0)
}

// ---- CodeBuffer ------------------------------------------------------------

///|
priv struct EncCodeBuffer {
  buffer : FixedArray[Byte]
  mut pos : Int
  mut flags_offset : Int
  mut flags_left : Int
  mut total_bytes : Int
}

///|
fn EncCodeBuffer::new() -> EncCodeBuffer {
  EncCodeBuffer::{
    buffer: FixedArray::make(ENC_CODE_BUFFER_SIZE, b'\x00'),
    pos: 1,
    flags_offset: 0,
    flags_left: 8,
    total_bytes: 0,
  }
}

///|
fn EncCodeBuffer::reset(self : EncCodeBuffer) -> Unit {
  self.pos = 1
  self.flags_offset = 0
  self.flags_left = 8
  self.total_bytes = 0
}

///|
fn EncCodeBuffer::init_flag(self : EncCodeBuffer) -> Unit {
  if self.flags_left == 8 {
    self.buffer[self.flags_offset] = b'\x00'
    self.pos = self.pos - 1
  } else {
    let v = self.buffer[self.flags_offset].to_int().reinterpret_as_uint()
    self.buffer[self.flags_offset] = byte_of_u(v >> self.flags_left)
  }
}

///|
fn EncCodeBuffer::push_literal(
  self : EncCodeBuffer,
  lit : Byte,
  lt : EncLiteralLengthTree,
) -> Unit {
  self.buffer[self.pos] = lit
  self.pos = self.pos + 1
  self.total_bytes = self.total_bytes + 1
  let fv = self.buffer[self.flags_offset].to_int().reinterpret_as_uint()
  self.buffer[self.flags_offset] = byte_of_u(fv >> 1)
  self.flags_left = self.flags_left - 1
  if self.flags_left == 0 {
    self.flags_left = 8
    self.flags_offset = self.pos
    self.pos = self.pos + 1
  }
  let idx = lit.to_int()
  lt.counts[idx] = lt.counts[idx] + 1
}

///|
fn EncCodeBuffer::push_match(
  self : EncCodeBuffer,
  len : Int,
  dist0 : Int,
  lt : EncLiteralLengthTree,
  dt : EncDistanceTree,
) -> Unit {
  // dist0 is the actual distance (>=1).
  self.total_bytes = self.total_bytes + len
  self.buffer[self.pos] = (len - ENC_MIN_MATCH_LEN).to_byte()
  let dist = dist0 - 1
  self.buffer[self.pos + 1] = (dist & 0xFF).to_byte()
  self.buffer[self.pos + 2] = ((dist >> 8) & 0xFF).to_byte()
  self.pos = self.pos + 3
  let fv = self.buffer[self.flags_offset].to_int().reinterpret_as_uint()
  self.buffer[self.flags_offset] = byte_of_u((fv >> 1) | 0x80)
  self.flags_left = self.flags_left - 1
  if self.flags_left == 0 {
    self.flags_left = 8
    self.flags_offset = self.pos
    self.pos = self.pos + 1
  }
  let (lsym, _, _) = enc_len_info(len)
  lt.counts[lsym] = lt.counts[lsym] + 1
  let (dsym, _, _) = enc_dist_info(dist0)
  dt.counts[dsym] = dt.counts[dsym] + 1
}

///|
fn EncCodeBuffer::emit(
  self : EncCodeBuffer,
  sink : Sink,
  lt : EncLiteralLengthTree,
  dt : EncDistanceTree,
) -> Unit raise YaziError {
  let mut flags : UInt = 1
  let snap = sink.snapshot()
  let bits = FastBits::new(snap.bit_buffer, snap.bits_in)
  let mut i = 0
  while i < self.pos {
    if flags == 1 {
      flags = self.buffer[i].to_int().reinterpret_as_uint() | 0x100
      i = i + 1
    }
    if (flags & 1) != 0 {
      if bits.bits_in > 16 {
        bits.flush(sink)
      }
      let match_len = self.buffer[i].to_int()
      let lo = self.buffer[i + 1].to_int()
      let hi = self.buffer[i + 2].to_int()
      let match_dist = (lo | (hi << 8)) + 1
      i = i + 3
      let len0 = match_len + ENC_MIN_MATCH_LEN
      let (lsym, lextra, lextra_bits) = enc_len_info(len0)
      bits.put(lt.codes[lsym], lt.code_sizes[lsym])
      if lextra_bits != 0 {
        bits.put(lextra, lextra_bits)
      }
      let (dsym, dextra, dextra_bits) = enc_dist_info(match_dist)
      bits.put(dt.codes[dsym], dt.code_sizes[dsym])
      if dextra_bits != 0 {
        bits.put(dextra, dextra_bits)
      }
    } else {
      let lit = self.buffer[i].to_int()
      i = i + 1
      if bits.bits_in > 48 {
        bits.flush(sink)
      }
      bits.put(lt.codes[lit], lt.code_sizes[lit])
    }
    flags = flags >> 1
  }
  bits.flush(sink)
  sink.set_bit_buffer(bits.bit_buffer.to_uint(), bits.bits_in)
  sink.put_bits(lt.codes[256], lt.code_sizes[256])
}

// ---- Dictionary ------------------------------------------------------------

///|
priv struct EncDictionary {
  dict : FixedArray[Byte]
  next : FixedArray[UInt]
  hash : FixedArray[UInt]
  mut code_buffer_offset : Int
  mut max_probes0 : Int
  mut max_probes1 : Int
  mut lookahead_size : Int
  mut lookahead_pos : Int
  mut len : Int
}

///|
fn probes_from_flags(flags : UInt) -> (Int, Int) {
  let probes = (flags & ENC_MAX_PROBES_MASK).reinterpret_as_int()
  let p0 = 1 + (probes + 2) / 3
  let p1 = 1 + ((probes >> 2) + 2) / 3
  (p0, p1)
}

///|
fn EncDictionary::new(flags : UInt) -> EncDictionary {
  let (p0, p1) = probes_from_flags(flags)
  EncDictionary::{
    dict: FixedArray::make(ENC_DICTIONARY_FULL_SIZE, b'\x00'),
    next: FixedArray::make(ENC_DICTIONARY_SIZE, 0),
    hash: FixedArray::make(ENC_HASH_SIZE, 0),
    code_buffer_offset: 0,
    max_probes0: p0,
    max_probes1: p1,
    lookahead_size: 0,
    lookahead_pos: 0,
    len: 0,
  }
}

///|
fn EncDictionary::get(self : EncDictionary, pos : Int) -> Byte {
  let p = if pos < 0 {
    0
  } else if pos >= self.dict.length() {
    self.dict.length() - 1
  } else {
    pos
  }
  self.dict[p]
}

///|
fn EncDictionary::read_u16(self : EncDictionary, pos : Int) -> UInt {
  let b0 = self.dict[pos].to_int().reinterpret_as_uint()
  let b1 = self.dict[pos + 1].to_int().reinterpret_as_uint()
  b0 | (b1 << 8)
}

///|
fn EncDictionary::read_u64(self : EncDictionary, pos : Int) -> UInt64 {
  let mut out : UInt64 = 0
  for i in 0..<8 {
    let b = self.dict[pos + i].to_int().to_uint64()
    out = out | (b << (i * 8))
  }
  out
}

///|
fn EncDictionary::find_match(
  self : EncDictionary,
  lookahead_pos : Int,
  max_dist : Int,
  max_match_len0 : Int,
  match_dist0 : Int,
  match_len0 : Int,
) -> (Int, Int) {
  let max_match_len = if max_match_len0 < ENC_MAX_MATCH_LEN {
    max_match_len0
  } else {
    ENC_MAX_MATCH_LEN
  }
  let mut match_len = if match_len0 > 1 { match_len0 } else { 1 }
  let mut match_dist = match_dist0
  if max_match_len <= match_len {
    return (match_dist, match_len)
  }
  let pos = lookahead_pos & ENC_DICTIONARY_SIZE_MASK
  let mut probe_pos = pos
  let mut num_probes_left = if match_len >= 32 {
    self.max_probes1
  } else {
    self.max_probes0
  }
  let mut c01 = self.read_u16(pos + match_len - 1)
  let s01 = self.read_u16(pos)
  while true {
    let mut dist = 0
    while true {
      num_probes_left = num_probes_left - 1
      if num_probes_left == 0 {
        return (match_dist, match_len)
      }
      let mut found = false
      for _ in 0..<3 {
        let next_probe_pos = self.next[probe_pos].reinterpret_as_int()
        dist = ((lookahead_pos - next_probe_pos).reinterpret_as_uint() & 0xFFFF).reinterpret_as_int()
        if next_probe_pos == 0 || dist > max_dist {
          return (match_dist, match_len)
        }
        probe_pos = next_probe_pos & ENC_DICTIONARY_SIZE_MASK
        if self.read_u16(probe_pos + match_len - 1) == c01 {
          found = true
          break
        }
      }
      if found {
        break
      }
    }
    if dist == 0 {
      return (match_dist, match_len)
    }
    if self.read_u16(probe_pos) != s01 {
      continue
    }
    let mut p = pos + 2
    let mut q = probe_pos + 2
    let mut retry_outer = false
    for _ in 0..<32 {
      let p_data = self.read_u64(p)
      let q_data = self.read_u64(q)
      let xor_data = p_data ^ q_data
      if xor_data == 0 {
        p = p + 8
        q = q + 8
      } else {
        let trailing = xor_data.ctz()
        let probe_len = p - pos + (trailing >> 3)
        if probe_len > match_len {
          match_dist = dist
          match_len = if probe_len < max_match_len {
            probe_len
          } else {
            max_match_len
          }
          if match_len == max_match_len {
            return (match_dist, match_len)
          }
          c01 = self.read_u16(pos + match_len - 1)
        }
        retry_outer = true
        break
      }
    }
    if retry_outer {
      continue
    }
    return (
      dist,
      if ENC_MAX_MATCH_LEN < max_match_len {
        ENC_MAX_MATCH_LEN
      } else {
        max_match_len
      },
    )
  }
  (match_dist, match_len)
}

// ---- DeflateContext --------------------------------------------------------

///|
priv struct EncDeflateContext {
  mut flags : UInt
  mut ready : Bool
  mut zlib : Bool
  mut level : CompressionLevel
  mut strategy : CompressionStrategy
  mut greedy_parsing : Bool
  mut block_index : UInt
  mut saved_match_dist : Int
  mut saved_match_len : Int
  mut saved_lit : Byte
  mut saved_bit_buffer : UInt
  mut saved_bits_in : Int
  mut adler32 : Adler32
  lt : EncLiteralLengthTree
  dt : EncDistanceTree
  pt : EncPrecodeTree
  cb : EncCodeBuffer
  dict : EncDictionary
}

///|
fn EncDeflateContext::new(
  format : Format,
  level : CompressionLevel,
  strategy : CompressionStrategy,
) -> EncDeflateContext {
  let zlib = match format {
    Format::Zlib => true
    _ => false
  }
  let flags = enc_make_flags(zlib, level, strategy)
  let (p0, p1) = probes_from_flags(flags)
  let dict = EncDictionary::new(flags)
  dict.max_probes0 = p0
  dict.max_probes1 = p1
  EncDeflateContext::{
    flags,
    ready: true,
    zlib,
    level,
    strategy,
    greedy_parsing: (flags & ENC_GREEDY_PARSING) != 0,
    block_index: 0,
    saved_match_dist: 0,
    saved_match_len: 0,
    saved_lit: b'\x00',
    saved_bit_buffer: 0,
    saved_bits_in: 0,
    adler32: Adler32::new(),
    lt: EncLiteralLengthTree::new(),
    dt: EncDistanceTree::new(),
    pt: EncPrecodeTree::new(),
    cb: EncCodeBuffer::new(),
    dict,
  }
}

///|
fn EncDeflateContext::reset(self : EncDeflateContext, zlib : Bool) -> Unit {
  if self.ready && zlib == self.zlib {
    return
  }
  let flags = enc_make_flags(zlib, self.level, self.strategy)
  let (p0, p1) = probes_from_flags(flags)
  self.zlib = zlib
  self.flags = flags
  self.greedy_parsing = (flags & ENC_GREEDY_PARSING) != 0
  self.block_index = 0
  self.saved_lit = b'\x00'
  self.saved_match_dist = 0
  self.saved_match_len = 0
  self.saved_bit_buffer = 0
  self.saved_bits_in = 0
  self.dict.code_buffer_offset = 0
  self.dict.len = 0
  self.dict.lookahead_pos = 0
  self.dict.lookahead_size = 0
  self.dict.max_probes0 = p0
  self.dict.max_probes1 = p1
  self.cb.reset()
  if !self.ready {
    self.lt.reset()
    self.dt.reset()
    self.pt.reset()
  }
  self.ready = true
  self.adler32 = Adler32::new()
}

///|
fn EncDeflateContext::deflate(
  self : EncDeflateContext,
  buf : Bytes,
  sink : Sink,
  is_last : Bool,
) -> Unit raise YaziError {
  if !is_last && buf.length() == 0 {
    return
  }
  self.deflate_inner(buf, sink, is_last)
  if (self.flags & ENC_WRITE_ZLIB_HEADER) != 0 {
    self.adler32.update(buf)
  }
}

///|
fn EncDeflateContext::deflate_inner(
  self : EncDeflateContext,
  data : Bytes,
  sink : Sink,
  is_last : Bool,
) -> Unit raise YaziError {
  self.ready = false
  let mut src_pos = 0
  let mut lookahead_size = self.dict.lookahead_size
  let mut lookahead_pos = self.dict.lookahead_pos
  let mut saved_lit = self.saved_lit
  let mut saved_match_dist = self.saved_match_dist
  let mut saved_match_len = self.saved_match_len
  while src_pos < data.length() || (is_last && lookahead_size != 0) {
    let src_left = data.length() - src_pos
    let num_bytes_to_process = if src_left < ENC_MAX_MATCH_LEN - lookahead_size {
      src_left
    } else {
      ENC_MAX_MATCH_LEN - lookahead_size
    }
    if lookahead_size + self.dict.len >= ENC_MIN_MATCH_LEN - 1 &&
      num_bytes_to_process > 0 {
      let mut dst_pos = (lookahead_pos + lookahead_size) &
        ENC_DICTIONARY_SIZE_MASK
      let mut ins_pos = lookahead_pos + lookahead_size - 2
      let h0 = self.dict.dict[ins_pos & ENC_DICTIONARY_SIZE_MASK]
        .to_int()
        .reinterpret_as_uint()
      let h1 = self.dict.dict[(ins_pos + 1) & ENC_DICTIONARY_SIZE_MASK]
        .to_int()
        .reinterpret_as_uint()
      let mut hash : UInt = (h0 << ENC_HASH_SHIFT) ^ h1
      lookahead_size = lookahead_size + num_bytes_to_process
      for k in 0..<num_bytes_to_process {
        let c = data[src_pos + k]
        self.dict.dict[dst_pos] = c
        if dst_pos < ENC_MAX_MATCH_LEN - 1 {
          self.dict.dict[ENC_DICTIONARY_SIZE + dst_pos] = c
        }
        hash = ((hash << ENC_HASH_SHIFT) ^ c.to_int().reinterpret_as_uint()) &
          (ENC_HASH_SIZE - 1).reinterpret_as_uint()
        let hi = hash.reinterpret_as_int()
        self.dict.next[ins_pos & ENC_DICTIONARY_SIZE_MASK] = self.dict.hash[hi]
        self.dict.hash[hi] = ins_pos.reinterpret_as_uint() & 0xFFFF
        dst_pos = (dst_pos + 1) & ENC_DICTIONARY_SIZE_MASK
        ins_pos = ins_pos + 1
      }
      src_pos = src_pos + num_bytes_to_process
    } else {
      for k in 0..<num_bytes_to_process {
        let c = data[src_pos + k]
        let dst_pos = (lookahead_pos + lookahead_size) &
          ENC_DICTIONARY_SIZE_MASK
        self.dict.dict[dst_pos] = c
        if dst_pos < ENC_MAX_MATCH_LEN - 1 {
          self.dict.dict[ENC_DICTIONARY_SIZE + dst_pos] = c
        }
        lookahead_size = lookahead_size + 1
        if lookahead_size + self.dict.len >= ENC_MIN_MATCH_LEN {
          let ins_pos = lookahead_pos + lookahead_size - 3
          let b0 = self.dict.dict[ins_pos & ENC_DICTIONARY_SIZE_MASK]
            .to_int()
            .reinterpret_as_uint()
          let b1 = self.dict.dict[(ins_pos + 1) & ENC_DICTIONARY_SIZE_MASK]
            .to_int()
            .reinterpret_as_uint()
          let cu = c.to_int().reinterpret_as_uint()
          let hash : UInt = (
              (b0 << (ENC_HASH_SHIFT * 2)) ^ ((b1 << ENC_HASH_SHIFT) ^ cu)
            ) &
            (ENC_HASH_SIZE - 1).reinterpret_as_uint()
          let hi = hash.reinterpret_as_int()
          self.dict.next[ins_pos & ENC_DICTIONARY_SIZE_MASK] = self.dict.hash[hi]
          self.dict.hash[hi] = ins_pos.reinterpret_as_uint() & 0xFFFF
        }
      }
      src_pos = src_pos + num_bytes_to_process
    }
    if self.dict.len > ENC_DICTIONARY_SIZE - lookahead_size {
      self.dict.len = ENC_DICTIONARY_SIZE - lookahead_size
    }
    if lookahead_size < ENC_MAX_MATCH_LEN && !is_last {
      break
    }
    let mut len_to_move = 1
    let mut cur_match_dist = 0
    let mut cur_match_len = if saved_match_len != 0 {
      saved_match_len
    } else {
      ENC_MIN_MATCH_LEN - 1
    }
    let cur_pos = lookahead_pos & ENC_DICTIONARY_SIZE_MASK
    if (self.flags & (ENC_RLE_MATCHES | ENC_FORCE_RAW)) != 0 {
      if self.dict.len != 0 && (self.flags & ENC_FORCE_RAW) == 0 {
        let c = self.dict.dict[(cur_pos - 1) & ENC_DICTIONARY_SIZE_MASK]
        let mut run = 0
        while run < lookahead_size && self.dict.dict[cur_pos + run] == c {
          run = run + 1
        }
        cur_match_len = run
        if cur_match_len < ENC_MIN_MATCH_LEN {
          cur_match_len = 0
        } else {
          cur_match_dist = 1
        }
      }
    } else {
      let (d, l) = self.dict.find_match(
        lookahead_pos,
        self.dict.len,
        lookahead_size,
        cur_match_dist,
        cur_match_len,
      )
      cur_match_dist = d
      cur_match_len = l
    }
    let far_and_small = cur_match_len == ENC_MIN_MATCH_LEN &&
      cur_match_dist >= 8 * 1024
    let filter_small = (self.flags & ENC_FILTER_MATCHES) != 0 &&
      cur_match_len <= 5
    if far_and_small || filter_small || cur_pos == cur_match_dist {
      cur_match_dist = 0
      cur_match_len = 0
    }
    if saved_match_len != 0 {
      if cur_match_len > saved_match_len {
        self.cb.push_literal(saved_lit, self.lt)
        if cur_match_len >= 128 {
          self.cb.push_match(cur_match_len, cur_match_dist, self.lt, self.dt)
          saved_match_len = 0
          len_to_move = cur_match_len
        } else {
          saved_lit = self.dict.get(cur_pos)
          saved_match_dist = cur_match_dist
          saved_match_len = cur_match_len
        }
      } else {
        self.cb.push_match(saved_match_len, saved_match_dist, self.lt, self.dt)
        len_to_move = saved_match_len - 1
        saved_match_len = 0
      }
    } else if cur_match_dist == 0 {
      self.cb.push_literal(self.dict.get(cur_pos), self.lt)
    } else if self.greedy_parsing ||
      (self.flags & ENC_RLE_MATCHES) != 0 ||
      cur_match_len >= 128 {
      self.cb.push_match(cur_match_len, cur_match_dist, self.lt, self.dt)
      len_to_move = cur_match_len
    } else {
      saved_lit = self.dict.get(cur_pos)
      saved_match_dist = cur_match_dist
      saved_match_len = cur_match_len
    }
    lookahead_pos = lookahead_pos + len_to_move
    lookahead_size = lookahead_size - len_to_move
    self.dict.len = self.dict.len + len_to_move
    if self.dict.len > ENC_DICTIONARY_SIZE {
      self.dict.len = ENC_DICTIONARY_SIZE
    }
    let lz_buf_tight = self.cb.pos > ENC_CODE_BUFFER_SIZE - 8
    let raw = (self.flags & ENC_FORCE_RAW) != 0
    let fat = (self.cb.pos * 115) >> 7 >= self.cb.total_bytes
    let fat_or_raw = self.cb.total_bytes > 31 * 1024 && (fat || raw)
    if lz_buf_tight || fat_or_raw {
      self.dict.lookahead_size = lookahead_size
      self.dict.lookahead_pos = lookahead_pos
      self.flush_block(sink, false)
    }
  }
  self.dict.lookahead_size = lookahead_size
  self.dict.lookahead_pos = lookahead_pos
  self.saved_lit = saved_lit
  self.saved_match_dist = saved_match_dist
  self.saved_match_len = saved_match_len
}

///|
fn EncDeflateContext::start_static_block(
  self : EncDeflateContext,
  sink : Sink,
) -> Unit raise YaziError {
  let lengths = self.lt.code_sizes
  for i in 0..<144 {
    lengths[i] = 8
  }
  for i in 144..<256 {
    lengths[i] = 9
  }
  for i in 256..<280 {
    lengths[i] = 7
  }
  for i in 280..<288 {
    lengths[i] = 8
  }
  for i in 0..<ENC_DISTANCE_TREE_SIZE {
    self.dt.code_sizes[i] = 5
  }
  self.lt.optimize(true)
  self.dt.optimize(true)
  sink.put_bits(1, 2)
}

///|
priv struct EncRle {
  mut prev : Int
  mut repeat_count : Int
  mut z_count : Int
}

///|
fn EncRle::new() -> EncRle {
  EncRle::{ prev: 0xFF, repeat_count: 0, z_count: 0 }
}

///|
fn EncRle::emit_prev(
  self : EncRle,
  packed : Array[Int],
  pt : EncPrecodeTree,
) -> Unit {
  if self.repeat_count == 0 {
    return
  }
  if self.repeat_count < 3 {
    pt.counts[self.prev] = pt.counts[self.prev] +
      self.repeat_count.reinterpret_as_uint()
    while self.repeat_count != 0 {
      packed.push(self.prev)
      self.repeat_count = self.repeat_count - 1
    }
  } else {
    pt.counts[16] = pt.counts[16] + 1
    packed.push(16)
    packed.push(self.repeat_count - 3)
  }
  self.repeat_count = 0
}

///|
fn EncRle::emit_zero(
  self : EncRle,
  packed : Array[Int],
  pt : EncPrecodeTree,
) -> Unit {
  if self.z_count == 0 {
    return
  }
  if self.z_count < 3 {
    pt.counts[0] = pt.counts[0] + self.z_count.reinterpret_as_uint()
    while self.z_count != 0 {
      packed.push(0)
      self.z_count = self.z_count - 1
    }
  } else if self.z_count <= 10 {
    pt.counts[17] = pt.counts[17] + 1
    packed.push(17)
    packed.push(self.z_count - 3)
  } else {
    pt.counts[18] = pt.counts[18] + 1
    packed.push(18)
    packed.push(self.z_count - 11)
  }
  self.z_count = 0
}

///|
let enc_precode_swizzle : Array[Int] = [
  16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
]

///|
fn EncDeflateContext::start_dynamic_block(
  self : EncDeflateContext,
  sink : Sink,
) -> Unit raise YaziError {
  // Ensure EOB exists.
  self.lt.counts[256] = 1
  self.lt.optimize(false)
  self.dt.optimize(false)
  let mut num_lit_codes = 286
  while num_lit_codes > 257 && self.lt.code_sizes[num_lit_codes - 1] == 0 {
    num_lit_codes = num_lit_codes - 1
  }
  let mut num_dist_codes = 30
  while num_dist_codes > 1 && self.dt.code_sizes[num_dist_codes - 1] == 0 {
    num_dist_codes = num_dist_codes - 1
  }
  let code_sizes_to_pack : Array[Int] = []
  for i in 0..<num_lit_codes {
    code_sizes_to_pack.push(self.lt.code_sizes[i])
  }
  for i in 0..<num_dist_codes {
    code_sizes_to_pack.push(self.dt.code_sizes[i])
  }
  let packed : Array[Int] = []
  for i in 0..<ENC_PRECODE_TREE_SIZE {
    self.pt.counts[i] = 0
  }
  let rle = EncRle::new()
  for i in 0..<code_sizes_to_pack.length() {
    let cs = code_sizes_to_pack[i]
    if cs == 0 {
      rle.emit_prev(packed, self.pt)
      rle.z_count = rle.z_count + 1
      if rle.z_count == 138 {
        rle.emit_zero(packed, self.pt)
      }
    } else {
      rle.emit_zero(packed, self.pt)
      if cs != rle.prev {
        rle.emit_prev(packed, self.pt)
        self.pt.counts[cs] = self.pt.counts[cs] + 1
        packed.push(cs)
      } else {
        rle.repeat_count = rle.repeat_count + 1
        if rle.repeat_count == 6 {
          rle.emit_prev(packed, self.pt)
        }
      }
    }
    rle.prev = cs
  }
  if rle.repeat_count != 0 {
    rle.emit_prev(packed, self.pt)
  } else {
    rle.emit_zero(packed, self.pt)
  }
  self.pt.optimize()
  sink.put_bits(2, 2)
  sink.put_bits((num_lit_codes - 257).reinterpret_as_uint(), 5)
  sink.put_bits((num_dist_codes - 1).reinterpret_as_uint(), 5)
  let mut num_bit_lengths = 0
  let mut i = 18
  while i >= 0 {
    let sw = enc_precode_swizzle[i]
    if self.pt.code_sizes[sw] != 0 {
      num_bit_lengths = i
      break
    }
    i = i - 1
  }
  if num_bit_lengths + 1 < 4 {
    num_bit_lengths = 3
  }
  sink.put_bits((num_bit_lengths + 1 - 4).reinterpret_as_uint(), 4)
  for i in 0..<(num_bit_lengths + 1) {
    let sw = enc_precode_swizzle[i]
    sink.put_bits(self.pt.code_sizes[sw].reinterpret_as_uint(), 3)
  }
  let mut j = 0
  while j < packed.length() {
    let code = packed[j]
    j = j + 1
    sink.put_bits(self.pt.codes[code], self.pt.code_sizes[code])
    if code >= 16 {
      let extra = packed[j]
      j = j + 1
      let eb = match code {
        16 => 2
        17 => 3
        _ => 7
      }
      sink.put_bits(extra.reinterpret_as_uint(), eb)
    }
  }
}

///|
fn EncDeflateContext::emit_block(
  self : EncDeflateContext,
  sink : Sink,
  is_static : Bool,
) -> Unit raise YaziError {
  if is_static {
    self.start_static_block(sink)
  } else {
    self.start_dynamic_block(sink)
  }
  self.cb.emit(sink, self.lt, self.dt)
}

///|
fn EncDeflateContext::flush_block(
  self : EncDeflateContext,
  sink : Sink,
  finish : Bool,
) -> Unit raise YaziError {
  sink.set_bit_buffer(self.saved_bit_buffer, self.saved_bits_in)
  let use_raw_a = (self.flags & ENC_FORCE_RAW) != 0
  let use_raw_b = self.dict.lookahead_pos - self.dict.code_buffer_offset <=
    self.dict.len
  let use_raw_block = use_raw_a && use_raw_b
  self.cb.init_flag()
  if (self.flags & ENC_WRITE_ZLIB_HEADER) != 0 && self.block_index == 0 {
    let (cmf, flg) = enc_make_zlib_header(self.flags)
    sink.put_bits(cmf, 8)
    sink.put_bits(flg, 8)
  }
  sink.put_bits(if finish { 1 } else { 0 }, 1)
  let snapshot = sink.snapshot()
  let mut comp_success = false
  if !use_raw_block {
    let use_static = (self.flags & ENC_FORCE_STATIC) != 0 ||
      self.cb.total_bytes < 48
    self.emit_block(sink, use_static)
    comp_success = true
  }
  let end_pos = sink.snapshot().pos
  let expanded_a = self.cb.total_bytes > 32
  let expanded_b = end_pos - snapshot.pos + 1 >= self.cb.total_bytes
  let expanded_c = self.dict.lookahead_pos - self.dict.code_buffer_offset <=
    self.dict.len
  let expanded = expanded_a && expanded_b && expanded_c
  if use_raw_block || expanded {
    sink.restore(snapshot)
    sink.put_bits(0, 2)
    sink.pad()
    let len_u = self.cb.total_bytes.reinterpret_as_uint()
    sink.put_bits(len_u & 0xFFFF, 16)
    sink.put_bits((len_u ^ 0xFFFF) & 0xFFFF, 16)
    for i in 0..<self.cb.total_bytes {
      let p = (self.dict.code_buffer_offset + i) & ENC_DICTIONARY_SIZE_MASK
      sink.put_bits(self.dict.dict[p].to_int().reinterpret_as_uint(), 8)
    }
  } else if !comp_success {
    sink.restore(snapshot)
    self.emit_block(sink, true)
  }
  if finish {
    sink.pad()
    if (self.flags & ENC_WRITE_ZLIB_HEADER) != 0 {
      let mut adler = self.adler32.finish()
      for _ in 0..<4 {
        sink.put_bits((adler >> 24) & 0xFF, 8)
        adler = adler << 8
      }
    }
  }
  self.lt.reset()
  self.dt.reset()
  self.cb.pos = 1
  self.cb.flags_offset = 0
  self.cb.flags_left = 8
  self.dict.code_buffer_offset = self.dict.code_buffer_offset +
    self.cb.total_bytes
  self.cb.total_bytes = 0
  self.block_index = self.block_index + 1
  let snap2 = sink.snapshot()
  self.saved_bit_buffer = snap2.bit_buffer
  self.saved_bits_in = snap2.bits_in
}
