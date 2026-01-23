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
/// RFC 1950/1951 decompression implementation (zlib wrapper + DEFLATE).
///
/// Ported from `yazi/src/decode.rs` (Apache-2.0 OR MIT).
fn u32_of_byte(b : Byte) -> UInt {
  b.to_int().reinterpret_as_uint()
}

///|
fn byte_of_u(v : UInt) -> Byte {
  v.reinterpret_as_int().to_byte()
}

// ---- Public API ------------------------------------------------------------

///|
/// Stateful context for decompression.
struct Decoder {
  ctx : Ref[InflateContext]
}

///|
pub fn Decoder::new() -> Decoder {
  Decoder::{ ctx: Ref::new(InflateContext::new()) }
}

///|
/// Sets the expected format of the input data for the next usage of the decoder.
pub fn Decoder::set_format(self : Decoder, format : Format) -> Unit {
  let zlib = match format {
    Format::Zlib => true
    _ => false
  }
  self.ctx.val.reset(zlib)
}

///|
/// Decompression stream combining a decoder context with an output.
struct DecoderStream {
  ctx : Ref[InflateContext]
  sink : SinkVec
  mut finished : Bool
}

///|
/// Decompression stream that writes into a fixed-size buffer.
///
/// The buffer must be pre-sized. If it is too small to hold the decompressed
/// output, `YaziError::Overflow` is raised.
struct DecoderBufStream {
  inner : DecoderStream
  buf : Array[Byte]
  mut finished : Bool
}

///|
/// Creates a decoder stream that will append into the specified vector.
pub fn Decoder::stream_into_vec(
  self : Decoder,
  vec : Array[Byte],
) -> DecoderStream {
  // Mimic upstream: creating a stream resets transient state for reuse.
  let zlib = self.ctx.val.zlib
  self.ctx.val.reset(zlib)
  DecoderStream::{ ctx: self.ctx, sink: SinkVec::new(vec), finished: false }
}

///|
/// Creates a decoder stream that will write into the specified buffer.
pub fn Decoder::stream_into_buf(
  self : Decoder,
  buf : Array[Byte],
) -> DecoderBufStream {
  let tmp = []
  let inner = self.stream_into_vec(tmp)
  DecoderBufStream::{ inner, buf, finished: false }
}

///|
pub fn DecoderStream::write(
  self : DecoderStream,
  buf : Bytes,
) -> Unit raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  self.ctx.val.inflate(buf, self.sink, false)
}

///|
pub fn DecoderBufStream::write(
  self : DecoderBufStream,
  buf : Bytes,
) -> Unit raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  self.inner.write(buf)
  if self.inner.sink.buffer.length() > self.buf.length() {
    self.finished = true
    self.inner.finished = true
    raise YaziError::Overflow
  }
}

///|
pub fn DecoderStream::decompressed_size(self : DecoderStream) -> UInt64 {
  self.sink.written()
}

///|
pub fn DecoderBufStream::decompressed_size(self : DecoderBufStream) -> UInt64 {
  self.inner.decompressed_size()
}

///|
/// Consumes the stream, flushing any input that may be buffered.
/// Returns the decompressed byte count and an optional checksum if zlib encoded.
pub fn DecoderStream::finish(
  self : DecoderStream,
) -> (UInt64, UInt?) raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  self.finished = true
  self.ctx.val.inflate(b"", self.sink, true)
  (self.sink.written(), self.ctx.val.checksum)
}

///|
pub fn DecoderBufStream::finish(
  self : DecoderBufStream,
) -> (UInt64, UInt?) raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  let (written, checksum) = self.inner.finish()
  let n = self.inner.sink.buffer.length()
  if n > self.buf.length() {
    self.finished = true
    raise YaziError::Overflow
  }
  for i in 0..<n {
    self.buf[i] = self.inner.sink.buffer[i]
  }
  self.finished = true
  (written, checksum)
}

///|
/// Decompresses a buffer of the specified format into a vector.
///
/// On success, returns the decompressed bytes and optionally an Adler-32 checksum
/// if the source data was zlib encoded.
pub fn decompress(
  buf : Bytes,
  format : Format,
) -> (Array[Byte], UInt?) raise YaziError {
  let decoder = Decoder::new()
  decoder.set_format(format)
  let out = []
  let stream = decoder.stream_into_vec(out)
  stream.write(buf)
  let (_, checksum) = stream.finish()
  (out, checksum)
}

// ---- Internal implementation ----------------------------------------------

///|
priv enum State {
  Header
  Block
  Copy(Int)
  Inflate
  Match(UInt)
}

///|
priv struct InflateContext {
  mut zlib : Bool
  mut state : State
  remainder : Array[Byte]
  mut bit_buffer : UInt64
  mut bits_in : UInt
  trees : Trees
  mut checksum : UInt?
  mut last_block : Bool
}

///|
fn InflateContext::new() -> InflateContext {
  InflateContext::{
    zlib: false,
    state: State::Block,
    remainder: [],
    bit_buffer: 0,
    bits_in: 0,
    trees: Trees::new(),
    checksum: None,
    last_block: false,
  }
}

///|
fn InflateContext::reset(self : InflateContext, zlib : Bool) -> Unit {
  self.zlib = zlib
  self.state = if zlib { State::Header } else { State::Block }
  self.remainder.clear()
  self.bit_buffer = 0
  self.bits_in = 0
  self.checksum = None
  self.last_block = false
}

///|
fn InflateContext::inflate(
  self : InflateContext,
  buf : Bytes,
  sink : SinkVec,
  is_last : Bool,
) -> Unit raise YaziError {
  // Merge buffered remainder + new input. This keeps the same public streaming
  // semantics as upstream, but is simpler than porting `Remainder` verbatim.
  let merged = []
  for b in self.remainder {
    merged.push(b)
  }
  for i in 0..<buf.length() {
    merged.push(buf[i])
  }
  self.remainder.clear()
  let data = Bytes::from_array(merged)
  let source = Source::new(data[:])
  let bits = Bits::new(self.bit_buffer, self.bits_in)
  let res = try {
    self.inflate_core(source, bits, sink, is_last)
    None
  } catch {
    err => Some(err)
  }
  self.bit_buffer = bits.bit_buffer
  self.bits_in = bits.bits_in
  match res {
    None => ()
    Some(YaziError::Underflow) => {
      if is_last {
        raise YaziError::Underflow
      }
      // Buffer unconsumed input and return to allow more bytes in future writes.
      let rem = source.remaining()
      for i in 0..<rem.length() {
        self.remainder.push(rem[i])
      }
    }
    Some(e) => raise e
  }
}

// ---- Bits/source -----------------------------------------------------------

///|
priv struct Source {
  data : BytesView
  mut pos : Int
}

///|
fn Source::new(data : BytesView) -> Source {
  Source::{ data, pos: 0 }
}

///|
fn Source::avail(self : Source) -> Int {
  self.data.length() - self.pos
}

///|
fn Source::remaining(self : Source) -> BytesView {
  self.data[self.pos:]
}

///|
fn Source::try_get(self : Source, len : Int) -> BytesView raise YaziError {
  let bytes = self.get(len)
  if bytes.length() == 0 {
    raise YaziError::Underflow
  }
  bytes
}

///|
fn Source::get(self : Source, len : Int) -> BytesView {
  let avail = self.avail()
  let take = if len <= avail { len } else { avail }
  let start = self.pos
  self.pos = self.pos + take
  self.data[start:start + take]
}

///|
priv struct Bits {
  mut bit_buffer : UInt64
  mut bits_in : UInt
}

///|
fn Bits::new(bit_buffer : UInt64, bits_in : UInt) -> Bits {
  Bits::{ bit_buffer, bits_in }
}

///|
fn Bits::bytes_available(self : Bits, source : Source) -> Int {
  source.avail() + self.bits_in.reinterpret_as_int() / 8
}

///|
fn Bits::fill(self : Bits, source : Source) -> UInt {
  // Fill up to 64 bits total.
  while self.bits_in <= 56 && source.avail() > 0 {
    let b = source.get(1)
    if b.length() == 0 {
      break
    }
    let v : UInt64 = u32_of_byte(b[0]).to_uint64()
    self.bit_buffer = self.bit_buffer | (v << self.bits_in.reinterpret_as_int())
    self.bits_in = self.bits_in + 8
  }
  self.bits_in
}

///|
fn Bits::try_pop_source(
  self : Bits,
  source : Source,
  len : UInt,
) -> UInt raise YaziError {
  if self.bits_in < len && self.fill(source) < len {
    raise YaziError::Underflow
  }
  let mask = ((1).to_uint64() << len.reinterpret_as_int()) - 1
  let bits = self.bit_buffer & mask
  self.bit_buffer = self.bit_buffer >> len.reinterpret_as_int()
  self.bits_in = self.bits_in - len
  bits.to_uint()
}

///|
fn Bits::try_pop(self : Bits, len : UInt) -> UInt raise YaziError {
  if self.bits_in < len {
    raise YaziError::Underflow
  }
  let mask = ((1).to_uint64() << len.reinterpret_as_int()) - 1
  let bits = self.bit_buffer & mask
  self.bit_buffer = self.bit_buffer >> len.reinterpret_as_int()
  self.bits_in = self.bits_in - len
  bits.to_uint()
}

///|
fn Bits::try_skip(self : Bits, len : UInt) -> Unit raise YaziError {
  if self.bits_in < len {
    raise YaziError::Underflow
  }
  self.bit_buffer = self.bit_buffer >> len.reinterpret_as_int()
  self.bits_in = self.bits_in - len
}

///|
fn Bits::peek(self : Bits, len : UInt) -> UInt {
  let mask = ((1).to_uint64() << len.reinterpret_as_int()) - 1
  (self.bit_buffer & mask).to_uint()
}

///|
fn Bits::pop(self : Bits, len : UInt) -> UInt {
  let bits = self.peek(len)
  self.bit_buffer = self.bit_buffer >> len.reinterpret_as_int()
  self.bits_in = self.bits_in - len
  bits
}

///|
fn Bits::skip(self : Bits, len : UInt) -> Unit {
  self.bit_buffer = self.bit_buffer >> len.reinterpret_as_int()
  self.bits_in = self.bits_in - len
}

// ---- Huffman tables --------------------------------------------------------

///|
const LITERAL_LENGTH_TREE_SIZE : Int = 1334

///|
const DISTANCE_TREE_SIZE : Int = 402

///|
const MAX_CODE_SIZE : Int = 15

///|
const MAX_LENGTHS : Int = 288 + 32

///|
const ENTRY_LITERAL : UInt = 0x40000000

///|
const ENTRY_SUBTABLE : UInt = 0x80000000

///|
const ENTRY_LENGTH_MASK : UInt = 0xFF

///|
const ENTRY_SHIFT : UInt = 8

///|
const LITERAL_LENGTH_TABLE_BITS : UInt = 10

///|
const DISTANCE_TABLE_BITS : UInt = 8

///|
const EXTRA_LENGTH_BITS_MASK : UInt = 0xFF

///|
const LENGTH_BASE_SHIFT : UInt = 8

///|
const EXTRA_DISTANCE_BITS_SHIFT : UInt = 16

///|
const DISTANCE_BASE_MASK : UInt = 0xFFFF

///|
let precode_swizzle : Array[Int] = [
  16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
]

///|
let precode_entries : Array[UInt] = [
  0x00000000, 0x00000100, 0x00000200, 0x00000300, 0x00000400, 0x00000500, 0x00000600,
  0x00000700, 0x00000800, 0x00000900, 0x00000A00, 0x00000B00, 0x00000C00, 0x00000D00,
  0x00000E00, 0x00000F00, 0x00001000, 0x00001100, 0x00001200,
]

// NOTE: Kept verbatim from upstream for fidelity.

///|
let literal_length_entries : Array[UInt] = [
  0x40000000, 0x40000100, 0x40000200, 0x40000300, 0x40000400, 0x40000500, 0x40000600,
  0x40000700, 0x40000800, 0x40000900, 0x40000A00, 0x40000B00, 0x40000C00, 0x40000D00,
  0x40000E00, 0x40000F00, 0x40001000, 0x40001100, 0x40001200, 0x40001300, 0x40001400,
  0x40001500, 0x40001600, 0x40001700, 0x40001800, 0x40001900, 0x40001A00, 0x40001B00,
  0x40001C00, 0x40001D00, 0x40001E00, 0x40001F00, 0x40002000, 0x40002100, 0x40002200,
  0x40002300, 0x40002400, 0x40002500, 0x40002600, 0x40002700, 0x40002800, 0x40002900,
  0x40002A00, 0x40002B00, 0x40002C00, 0x40002D00, 0x40002E00, 0x40002F00, 0x40003000,
  0x40003100, 0x40003200, 0x40003300, 0x40003400, 0x40003500, 0x40003600, 0x40003700,
  0x40003800, 0x40003900, 0x40003A00, 0x40003B00, 0x40003C00, 0x40003D00, 0x40003E00,
  0x40003F00, 0x40004000, 0x40004100, 0x40004200, 0x40004300, 0x40004400, 0x40004500,
  0x40004600, 0x40004700, 0x40004800, 0x40004900, 0x40004A00, 0x40004B00, 0x40004C00,
  0x40004D00, 0x40004E00, 0x40004F00, 0x40005000, 0x40005100, 0x40005200, 0x40005300,
  0x40005400, 0x40005500, 0x40005600, 0x40005700, 0x40005800, 0x40005900, 0x40005A00,
  0x40005B00, 0x40005C00, 0x40005D00, 0x40005E00, 0x40005F00, 0x40006000, 0x40006100,
  0x40006200, 0x40006300, 0x40006400, 0x40006500, 0x40006600, 0x40006700, 0x40006800,
  0x40006900, 0x40006A00, 0x40006B00, 0x40006C00, 0x40006D00, 0x40006E00, 0x40006F00,
  0x40007000, 0x40007100, 0x40007200, 0x40007300, 0x40007400, 0x40007500, 0x40007600,
  0x40007700, 0x40007800, 0x40007900, 0x40007A00, 0x40007B00, 0x40007C00, 0x40007D00,
  0x40007E00, 0x40007F00, 0x40008000, 0x40008100, 0x40008200, 0x40008300, 0x40008400,
  0x40008500, 0x40008600, 0x40008700, 0x40008800, 0x40008900, 0x40008A00, 0x40008B00,
  0x40008C00, 0x40008D00, 0x40008E00, 0x40008F00, 0x40009000, 0x40009100, 0x40009200,
  0x40009300, 0x40009400, 0x40009500, 0x40009600, 0x40009700, 0x40009800, 0x40009900,
  0x40009A00, 0x40009B00, 0x40009C00, 0x40009D00, 0x40009E00, 0x40009F00, 0x4000A000,
  0x4000A100, 0x4000A200, 0x4000A300, 0x4000A400, 0x4000A500, 0x4000A600, 0x4000A700,
  0x4000A800, 0x4000A900, 0x4000AA00, 0x4000AB00, 0x4000AC00, 0x4000AD00, 0x4000AE00,
  0x4000AF00, 0x4000B000, 0x4000B100, 0x4000B200, 0x4000B300, 0x4000B400, 0x4000B500,
  0x4000B600, 0x4000B700, 0x4000B800, 0x4000B900, 0x4000BA00, 0x4000BB00, 0x4000BC00,
  0x4000BD00, 0x4000BE00, 0x4000BF00, 0x4000C000, 0x4000C100, 0x4000C200, 0x4000C300,
  0x4000C400, 0x4000C500, 0x4000C600, 0x4000C700, 0x4000C800, 0x4000C900, 0x4000CA00,
  0x4000CB00, 0x4000CC00, 0x4000CD00, 0x4000CE00, 0x4000CF00, 0x4000D000, 0x4000D100,
  0x4000D200, 0x4000D300, 0x4000D400, 0x4000D500, 0x4000D600, 0x4000D700, 0x4000D800,
  0x4000D900, 0x4000DA00, 0x4000DB00, 0x4000DC00, 0x4000DD00, 0x4000DE00, 0x4000DF00,
  0x4000E000, 0x4000E100, 0x4000E200, 0x4000E300, 0x4000E400, 0x4000E500, 0x4000E600,
  0x4000E700, 0x4000E800, 0x4000E900, 0x4000EA00, 0x4000EB00, 0x4000EC00, 0x4000ED00,
  0x4000EE00, 0x4000EF00, 0x4000F000, 0x4000F100, 0x4000F200, 0x4000F300, 0x4000F400,
  0x4000F500, 0x4000F600, 0x4000F700, 0x4000F800, 0x4000F900, 0x4000FA00, 0x4000FB00,
  0x4000FC00, 0x4000FD00, 0x4000FE00, 0x4000FF00, 0x00000000, 0x00030000, 0x00040000,
  0x00050000, 0x00060000, 0x00070000, 0x00080000, 0x00090000, 0x000A0000, 0x000B0100,
  0x000D0100, 0x000F0100, 0x00110100, 0x00130200, 0x00170200, 0x001B0200, 0x001F0200,
  0x00230300, 0x002B0300, 0x00330300, 0x003B0300, 0x00430400, 0x00530400, 0x00630400,
  0x00730400, 0x00830500, 0x00A30500, 0x00C30500, 0x00E30500, 0x01020000, 0x01020000,
  0x01020000,
]

///|
let distance_entries : Array[UInt] = [
  0x00000100, 0x00000200, 0x00000300, 0x00000400, 0x01000500, 0x01000700, 0x02000900,
  0x02000D00, 0x03001100, 0x03001900, 0x04002100, 0x04003100, 0x05004100, 0x05006100,
  0x06008100, 0x0600C100, 0x07010100, 0x07018100, 0x08020100, 0x08030100, 0x09040100,
  0x09060100, 0x0A080100, 0x0A0C0100, 0x0B100100, 0x0B180100, 0x0C200100, 0x0C300100,
  0x0D400100, 0x0D600100, 0x0E800100, 0x0EC00100,
]

///|
priv struct LiteralLengthTree {
  table : Array[UInt]
}

///|
fn LiteralLengthTree::new() -> LiteralLengthTree {
  let t : Array[UInt] = []
  for _i in 0..<LITERAL_LENGTH_TREE_SIZE {
    t.push((0).reinterpret_as_uint())
  }
  LiteralLengthTree::{ table: t }
}

///|
fn LiteralLengthTree::build(
  self : LiteralLengthTree,
  lengths : Array[Int],
  n : Int,
) -> Bool {
  build_tree(self.table, lengths, 0, n, literal_length_entries, 10, 15)
}

///|
fn LiteralLengthTree::build_precode(
  self : LiteralLengthTree,
  lengths : Array[Int],
) -> Bool {
  build_tree(self.table, lengths, 0, 19, precode_entries, 7, 7)
}

///|
priv struct DistanceTree {
  table : Array[UInt]
}

///|
fn DistanceTree::new() -> DistanceTree {
  let t : Array[UInt] = []
  for _i in 0..<DISTANCE_TREE_SIZE {
    t.push((0).reinterpret_as_uint())
  }
  DistanceTree::{ table: t }
}

///|
fn DistanceTree::build(
  self : DistanceTree,
  lengths : Array[Int],
  start : Int,
  n : Int,
) -> Bool {
  build_tree(self.table, lengths, start, n, distance_entries, 8, 15)
}

///|
priv struct Trees {
  lt : LiteralLengthTree
  dt : DistanceTree
}

///|
fn Trees::new() -> Trees {
  Trees::{ lt: LiteralLengthTree::new(), dt: DistanceTree::new() }
}

///|
fn highest_pow2(x : Int) -> Int {
  let mut bit = 1
  while bit <= x {
    bit = bit << 1
  }
  bit >> 1
}

///|
fn build_tree(
  table : Array[UInt],
  lengths : Array[Int],
  start : Int,
  nsyms : Int,
  entries : Array[UInt],
  table_bits : Int,
  max_codeword_len : Int,
) -> Bool {
  let len_counts = []
  let offsets = []
  for _i in 0..<(MAX_CODE_SIZE + 1) {
    len_counts.push(0)
    offsets.push(0)
  }
  let sorted_entries : Array[UInt] = []
  for _i in 0..<288 {
    sorted_entries.push(0)
  }
  for i in 0..<nsyms {
    let len = lengths[start + i]
    len_counts[len] = len_counts[len] + 1
  }
  offsets[1] = len_counts[0]
  let mut codespace_used = 0
  for len in 1..<max_codeword_len {
    offsets[len + 1] = offsets[len] + len_counts[len]
    codespace_used = (codespace_used << 1) + len_counts[len]
  }
  codespace_used = (codespace_used << 1) + len_counts[max_codeword_len]
  for sym in 0..<nsyms {
    let len = lengths[start + sym]
    let idx = offsets[len]
    sorted_entries[idx] = entries[sym]
    offsets[len] = idx + 1
  }
  let sorted_start = offsets[0]
  if codespace_used > 1 << max_codeword_len {
    return false
  }
  if codespace_used < 1 << max_codeword_len {
    let entry = if codespace_used == 0 {
      entries[0] | 1
    } else {
      if codespace_used != 1 << (max_codeword_len - 1) || len_counts[1] != 1 {
        return false
      }
      sorted_entries[sorted_start] | 1
    }
    for i in 0..<(1 << table_bits) {
      table[i] = entry
    }
    return true
  }
  let mut len = 1
  let mut count = 0
  while true {
    count = len_counts[len & 15]
    if count != 0 {
      break
    }
    len = len + 1
  }
  let mut codeword = 0
  let mut cur_table_end = 1 << len
  let mut s = 0
  while len <= table_bits {
    while true {
      table[codeword] = sorted_entries[sorted_start + s] |
        len.reinterpret_as_uint()
      s = s + 1
      if codeword == cur_table_end - 1 {
        while len < table_bits {
          // Duplicate the existing entries.
          for i in 0..<cur_table_end {
            table[cur_table_end + i] = table[i]
          }
          cur_table_end = cur_table_end << 1
          len = len + 1
        }
        return true
      }
      let y = codeword ^ (cur_table_end - 1)
      let bit = highest_pow2(y)
      codeword = codeword & (bit - 1)
      codeword = codeword | bit
      count = count - 1
      if count == 0 {
        break
      }
    }
    while true {
      len = len + 1
      if len <= table_bits {
        for i in 0..<cur_table_end {
          table[cur_table_end + i] = table[i]
        }
        cur_table_end = cur_table_end << 1
      }
      count = len_counts[len & 15]
      if count != 0 {
        break
      }
    }
  }
  cur_table_end = 1 << table_bits
  let mut subtable_prefix = -1
  let mut subtable_start = 0
  while true {
    if (codeword & ((1 << table_bits) - 1)) != subtable_prefix {
      subtable_prefix = codeword & ((1 << table_bits) - 1)
      subtable_start = cur_table_end
      let mut subtable_bits = len - table_bits
      codespace_used = count
      while codespace_used < 1 << subtable_bits {
        subtable_bits = subtable_bits + 1
        codespace_used = (codespace_used << 1) +
          len_counts[table_bits + subtable_bits]
      }
      cur_table_end = subtable_start + (1 << subtable_bits)
      table[subtable_prefix] = ENTRY_SUBTABLE |
        (subtable_start.reinterpret_as_uint() << 8) |
        subtable_bits.reinterpret_as_uint()
    }
    let entry = sorted_entries[sorted_start + s] |
      (len - table_bits).reinterpret_as_uint()
    s = s + 1
    let mut i = subtable_start + (codeword >> table_bits)
    let stride = 1 << (len - table_bits)
    while i < cur_table_end {
      table[i] = entry
      i = i + stride
    }
    if codeword == (1 << len) - 1 {
      return true
    }
    let y = codeword ^ ((1 << len) - 1)
    let bit = highest_pow2(y)
    codeword = codeword & (bit - 1)
    codeword = codeword | bit
    count = count - 1
    while count == 0 {
      len = len + 1
      count = len_counts[len & 15]
    }
  }
  false
}

// ---- zlib wrapper ----------------------------------------------------------

///|
fn verify_zlib_header(source : Source, bits : Bits) -> Unit raise YaziError {
  let cmf = bits.try_pop_source(source, 8)
  let flg = bits.try_pop_source(source, 8)
  if ((256).reinterpret_as_uint() * cmf + flg) % (31).reinterpret_as_uint() != 0 ||
    (cmf & 0x0F) != 8 ||
    (cmf >> 4).reinterpret_as_int() > 7 ||
    (flg & 0x20) != 0 {
    raise YaziError::InvalidBitstream
  }
}

///|
fn read_zlib_checksum(source : Source, bits : Bits) -> UInt raise YaziError {
  let b0 = bits.try_pop_source(source, 8)
  let b1 = bits.try_pop_source(source, 8)
  let b2 = bits.try_pop_source(source, 8)
  let b3 = bits.try_pop_source(source, 8)
  (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

// ---- Sink ------------------------------------------------------------------

///|
priv struct SinkVec {
  buffer : Array[Byte]
  start_pos : Int
  mut pos : Int
}

///|
fn SinkVec::new(buffer : Array[Byte]) -> SinkVec {
  let start = buffer.length()
  SinkVec::{ buffer, start_pos: start, pos: start }
}

///|
fn SinkVec::written(self : SinkVec) -> UInt64 {
  (self.pos - self.start_pos).to_uint64()
}

///|
fn SinkVec::push(self : SinkVec, byte : Byte) -> Unit {
  self.buffer.push(byte)
  self.pos = self.pos + 1
}

///|
fn SinkVec::write(self : SinkVec, bytes : BytesView) -> Unit {
  let n = bytes.length()
  for i in 0..<n {
    self.buffer.push(bytes[i])
  }
  self.pos = self.pos + n
}

///|
fn SinkVec::apply_match(
  self : SinkVec,
  dist : Int,
  len : Int,
) -> Unit raise YaziError {
  let buf_len = self.pos - self.start_pos
  if dist > buf_len {
    raise YaziError::InvalidBitstream
  }
  let start = self.pos - dist
  for i in 0..<len {
    let b = self.buffer[start + i]
    self.buffer.push(b)
  }
  self.pos = self.pos + len
}

// ---- Inflate core ----------------------------------------------------------

///|
fn decode_trees(
  source : Source,
  bits : Bits,
  lt : LiteralLengthTree,
  dt : DistanceTree,
  is_last : Bool,
) -> Unit raise YaziError {
  let lengths : Array[Int] = []
  for _i in 0..<MAX_LENGTHS {
    lengths.push(0)
  }
  bits.fill(source) |> ignore
  let ltlen = if !is_last {
    bits.pop(5).reinterpret_as_int() + 257
  } else {
    bits.try_pop(5).reinterpret_as_int() + 257
  }
  let dtlen = if !is_last {
    bits.pop(5).reinterpret_as_int() + 1
  } else {
    bits.try_pop(5).reinterpret_as_int() + 1
  }
  let ptlen = if !is_last {
    bits.pop(4).reinterpret_as_int() + 4
  } else {
    bits.try_pop(4).reinterpret_as_int() + 4
  }
  if ltlen > 286 || dtlen > 30 {
    raise YaziError::InvalidBitstream
  }
  // clear precode lengths
  for i in 0..<19 {
    lengths[i] = 0
  }
  bits.fill(source) |> ignore
  for i in 0..<ptlen {
    let code = precode_swizzle[i]
    let clen = bits.try_pop_source(source, 3).reinterpret_as_int()
    lengths[code] = clen
  }
  if !lt.build_precode(lengths) {
    raise YaziError::InvalidBitstream
  }
  let mut i = 0
  while i < ltlen + dtlen {
    if bits.bits_in < 7 {
      bits.fill(source) |> ignore
    }
    let entry = lt.table[bits.peek(7).reinterpret_as_int()]
    if !is_last {
      bits.skip(entry & ENTRY_LENGTH_MASK)
    } else {
      bits.try_skip(entry & ENTRY_LENGTH_MASK)
    }
    let presym = (entry >> ENTRY_SHIFT.reinterpret_as_int()).reinterpret_as_int()
    if presym < 16 {
      lengths[i] = presym
      i = i + 1
      continue
    }
    if bits.bits_in < 7 {
      bits.fill(source) |> ignore
    }
    if presym > 18 || (presym == 16 && i == 0) {
      raise YaziError::InvalidBitstream
    }
    let (extra_bits, extra) = match (presym - 16) & 3 {
      0 => (2, 3)
      1 => (3, 3)
      2 => (7, 11)
      _ => (0, 0)
    }
    let count = if !is_last {
      bits.pop(extra_bits.reinterpret_as_uint()).reinterpret_as_int() + extra
    } else {
      bits.try_pop(extra_bits.reinterpret_as_uint()).reinterpret_as_int() +
      extra
    }
    let l = if presym == 16 { lengths[i - 1] } else { 0 }
    if i + count > MAX_LENGTHS {
      raise YaziError::InvalidBitstream
    }
    for j in 0..<count {
      lengths[i + j] = l
    }
    i = i + count
  }
  if lengths[256] == 0 ||
    !lt.build(lengths, ltlen) ||
    !dt.build(lengths, ltlen, dtlen) {
    raise YaziError::InvalidBitstream
  }
}

///|
fn InflateContext::inflate_core(
  self : InflateContext,
  source : Source,
  bits : Bits,
  sink : SinkVec,
  is_last : Bool,
) -> Unit raise YaziError {
  while true {
    match self.state {
      State::Header => {
        if bits.bytes_available(source) < 2 {
          raise YaziError::Underflow
        }
        verify_zlib_header(source, bits)
        self.state = State::Block
      }
      State::Block => {
        if self.last_block {
          if self.zlib && self.checksum is None {
            bits.skip(bits.bits_in & 7)
            if bits.bytes_available(source) < 4 {
              raise YaziError::Underflow
            }
            self.checksum = Some(read_zlib_checksum(source, bits))
          }
          return
        }
        if bits.bytes_available(source) < 286 && !is_last {
          raise YaziError::Underflow
        }
        let header = bits.try_pop_source(source, 3)
        self.last_block = (header & 1) != 0
        match header >> 1 {
          0 => {
            bits.try_skip(bits.bits_in & 7)
            let parts : Array[UInt] = []
            for _i in 0..<4 {
              parts.push(0)
            }
            for i in 0..<4 {
              if bits.bits_in >= 8 {
                parts[i] = bits.pop(8)
              } else {
                if source.avail() <= 0 {
                  raise YaziError::InvalidBitstream
                }
                let b = source.get(1)
                if b.length() != 1 {
                  raise YaziError::InvalidBitstream
                }
                parts[i] = u32_of_byte(b[0])
              }
            }
            let length = parts[0] | (parts[1] << 8)
            let inv_length = parts[2] | (parts[3] << 8)
            if length != ((inv_length ^ 0xFFFF) & 0xFFFF) {
              raise YaziError::InvalidBitstream
            }
            let mut remaining = length.reinterpret_as_int()
            while bits.bits_in >= 8 && remaining > 0 {
              sink.push(byte_of_u(bits.pop(8)))
              remaining = remaining - 1
            }
            if bits.bits_in == 0 {
              bits.bit_buffer = 0
            }
            self.state = State::Copy(remaining)
            while remaining > 0 {
              let bytes = source.try_get(remaining)
              sink.write(bytes)
              remaining = remaining - bytes.length()
              self.state = State::Copy(remaining)
            }
            self.state = State::Block
          }
          1 => {
            // Fixed Huffman
            let ll_lengths : Array[Int] = []
            for _i in 0..<288 {
              ll_lengths.push(0)
            }
            for i in 0..<144 {
              ll_lengths[i] = 8
            }
            for i in 144..<256 {
              ll_lengths[i] = 9
            }
            for i in 256..<280 {
              ll_lengths[i] = 7
            }
            for i in 280..<288 {
              ll_lengths[i] = 8
            }
            let d_lengths : Array[Int] = []
            for _i in 0..<32 {
              d_lengths.push(5)
            }
            self.trees.lt.build(ll_lengths, 288) |> ignore
            self.trees.dt.build(d_lengths, 0, 32) |> ignore
            self.state = State::Inflate
          }
          2 => {
            decode_trees(source, bits, self.trees.lt, self.trees.dt, is_last)
            self.state = State::Inflate
          }
          _ => raise YaziError::InvalidBitstream
        }
      }
      State::Copy(remaining0) => {
        let mut remaining = remaining0
        while remaining > 0 {
          let bytes = source.try_get(remaining)
          sink.write(bytes)
          remaining = remaining - bytes.length()
          self.state = State::Copy(remaining)
        }
        self.state = State::Block
      }
      State::Inflate => {
        let lbits = Bits::new(bits.bit_buffer, bits.bits_in)
        let mut entry : UInt = 0
        if !is_last {
          while true {
            let mut handle_match = false
            while lbits.bits_in >= 15 {
              entry = self.trees.lt.table[lbits
                .peek(LITERAL_LENGTH_TABLE_BITS)
                .reinterpret_as_int()]
              if (entry & ENTRY_SUBTABLE) != 0 {
                lbits.skip(LITERAL_LENGTH_TABLE_BITS)
                entry = self.trees.lt.table[((
                    (entry >> ENTRY_SHIFT.reinterpret_as_int()) & 0xFFFF
                  ) +
                  lbits.peek(entry & ENTRY_LENGTH_MASK)).reinterpret_as_int()]
              }
              lbits.skip(entry & ENTRY_LENGTH_MASK)
              if (entry & ENTRY_LITERAL) == 0 {
                handle_match = true
                break
              }
              sink.push(byte_of_u(entry >> ENTRY_SHIFT.reinterpret_as_int()))
            }
            if !handle_match {
              if lbits.fill(source) >= 15 {
                entry = self.trees.lt.table[lbits
                  .peek(LITERAL_LENGTH_TABLE_BITS)
                  .reinterpret_as_int()]
                if (entry & ENTRY_SUBTABLE) != 0 {
                  lbits.skip(LITERAL_LENGTH_TABLE_BITS)
                  entry = self.trees.lt.table[((
                      (entry >> ENTRY_SHIFT.reinterpret_as_int()) & 0xFFFF
                    ) +
                    lbits.peek(entry & ENTRY_LENGTH_MASK)).reinterpret_as_int()]
                }
                lbits.skip(entry & ENTRY_LENGTH_MASK)
                if (entry & ENTRY_LITERAL) != 0 {
                  sink.push(
                    byte_of_u(entry >> ENTRY_SHIFT.reinterpret_as_int()),
                  )
                  continue
                }
              } else {
                bits.bit_buffer = lbits.bit_buffer
                bits.bits_in = lbits.bits_in
                raise YaziError::Underflow
              }
            }
            entry = entry >> ENTRY_SHIFT.reinterpret_as_int()
            if lbits.fill(source) >= 33 {
              let length = (entry >> LENGTH_BASE_SHIFT.reinterpret_as_int()).reinterpret_as_int() +
                lbits.pop(entry & EXTRA_LENGTH_BITS_MASK).reinterpret_as_int()
              if length == 0 {
                bits.bit_buffer = lbits.bit_buffer
                bits.bits_in = lbits.bits_in
                self.state = State::Block
                break
              }
              entry = self.trees.dt.table[lbits
                .peek(DISTANCE_TABLE_BITS)
                .reinterpret_as_int()]
              if (entry & ENTRY_SUBTABLE) != 0 {
                lbits.skip(DISTANCE_TABLE_BITS)
                entry = self.trees.dt.table[((
                    (entry >> ENTRY_SHIFT.reinterpret_as_int()) & 0xFFFF
                  ) +
                  lbits.peek(entry & ENTRY_LENGTH_MASK)).reinterpret_as_int()]
              }
              lbits.skip(entry & ENTRY_LENGTH_MASK)
              entry = entry >> ENTRY_SHIFT.reinterpret_as_int()
              let distance = (entry & DISTANCE_BASE_MASK).reinterpret_as_int() +
                lbits
                .pop(entry >> EXTRA_DISTANCE_BITS_SHIFT.reinterpret_as_int())
                .reinterpret_as_int()
              sink.apply_match(distance, length)
            } else {
              bits.bit_buffer = lbits.bit_buffer
              bits.bits_in = lbits.bits_in
              self.state = State::Match(entry)
              raise YaziError::Underflow
            }
          }
        } else {
          while true {
            if lbits.bits_in < 15 {
              lbits.fill(source) |> ignore
            }
            let mut e = self.trees.lt.table[lbits
              .peek(LITERAL_LENGTH_TABLE_BITS)
              .reinterpret_as_int()]
            if (e & ENTRY_SUBTABLE) != 0 {
              lbits.try_skip(LITERAL_LENGTH_TABLE_BITS)
              e = self.trees.lt.table[((
                  (e >> ENTRY_SHIFT.reinterpret_as_int()) & 0xFFFF
                ) +
                lbits.peek(e & ENTRY_LENGTH_MASK)).reinterpret_as_int()]
            }
            lbits.try_skip(e & ENTRY_LENGTH_MASK)
            if (e & ENTRY_LITERAL) != 0 {
              sink.push(byte_of_u(e >> ENTRY_SHIFT.reinterpret_as_int()))
              continue
            }
            e = e >> ENTRY_SHIFT.reinterpret_as_int()
            lbits.fill(source) |> ignore
            let length = (e >> LENGTH_BASE_SHIFT.reinterpret_as_int()).reinterpret_as_int() +
              lbits.try_pop(e & EXTRA_LENGTH_BITS_MASK).reinterpret_as_int()
            if length == 0 {
              bits.bit_buffer = lbits.bit_buffer
              bits.bits_in = lbits.bits_in
              self.state = State::Block
              break
            }
            e = self.trees.dt.table[lbits
              .peek(DISTANCE_TABLE_BITS)
              .reinterpret_as_int()]
            if (e & ENTRY_SUBTABLE) != 0 {
              lbits.try_skip(DISTANCE_TABLE_BITS)
              e = self.trees.dt.table[((
                  (e >> ENTRY_SHIFT.reinterpret_as_int()) & 0xFFFF
                ) +
                lbits.peek(e & ENTRY_LENGTH_MASK)).reinterpret_as_int()]
            }
            lbits.try_skip(e & ENTRY_LENGTH_MASK)
            e = e >> ENTRY_SHIFT.reinterpret_as_int()
            let distance = (e & DISTANCE_BASE_MASK).reinterpret_as_int() +
              lbits
              .try_pop(e >> EXTRA_DISTANCE_BITS_SHIFT.reinterpret_as_int())
              .reinterpret_as_int()
            sink.apply_match(distance, length)
          }
        }
      }
      State::Match(entry0) => {
        let mut entry = entry0
        let lbits = Bits::new(bits.bit_buffer, bits.bits_in)
        if !is_last {
          if lbits.fill(source) < 33 {
            bits.bit_buffer = lbits.bit_buffer
            bits.bits_in = lbits.bits_in
            raise YaziError::Underflow
          }
          let length = (entry >> LENGTH_BASE_SHIFT.reinterpret_as_int()).reinterpret_as_int() +
            lbits.pop(entry & EXTRA_LENGTH_BITS_MASK).reinterpret_as_int()
          if length == 0 {
            bits.bit_buffer = lbits.bit_buffer
            bits.bits_in = lbits.bits_in
            self.state = State::Block
            continue
          }
          entry = self.trees.dt.table[lbits
            .peek(DISTANCE_TABLE_BITS)
            .reinterpret_as_int()]
          if (entry & ENTRY_SUBTABLE) != 0 {
            lbits.skip(DISTANCE_TABLE_BITS)
            entry = self.trees.dt.table[((
                (entry >> ENTRY_SHIFT.reinterpret_as_int()) & 0xFFFF
              ) +
              lbits.peek(entry & ENTRY_LENGTH_MASK)).reinterpret_as_int()]
          }
          lbits.skip(entry & ENTRY_LENGTH_MASK)
          entry = entry >> ENTRY_SHIFT.reinterpret_as_int()
          let distance = (entry & DISTANCE_BASE_MASK).reinterpret_as_int() +
            lbits
            .pop(entry >> EXTRA_DISTANCE_BITS_SHIFT.reinterpret_as_int())
            .reinterpret_as_int()
          bits.bit_buffer = lbits.bit_buffer
          bits.bits_in = lbits.bits_in
          self.state = State::Inflate
          sink.apply_match(distance, length)
        } else {
          let length = (entry >> LENGTH_BASE_SHIFT.reinterpret_as_int()).reinterpret_as_int() +
            lbits.try_pop(entry & EXTRA_LENGTH_BITS_MASK).reinterpret_as_int()
          if length == 0 {
            bits.bit_buffer = lbits.bit_buffer
            bits.bits_in = lbits.bits_in
            self.state = State::Block
            continue
          }
          entry = self.trees.dt.table[lbits
            .peek(DISTANCE_TABLE_BITS)
            .reinterpret_as_int()]
          if (entry & ENTRY_SUBTABLE) != 0 {
            lbits.try_skip(DISTANCE_TABLE_BITS)
            entry = self.trees.dt.table[((
                (entry >> ENTRY_SHIFT.reinterpret_as_int()) & 0xFFFF
              ) +
              lbits.peek(entry & ENTRY_LENGTH_MASK)).reinterpret_as_int()]
          }
          lbits.try_skip(entry & ENTRY_LENGTH_MASK)
          entry = entry >> ENTRY_SHIFT.reinterpret_as_int()
          let distance = (entry & DISTANCE_BASE_MASK).reinterpret_as_int() +
            lbits
            .try_pop(entry >> EXTRA_DISTANCE_BITS_SHIFT.reinterpret_as_int())
            .reinterpret_as_int()
          bits.bit_buffer = lbits.bit_buffer
          bits.bits_in = lbits.bits_in
          self.state = State::Inflate
          sink.apply_match(distance, length)
        }
      }
    }
  }
}

// ---- Tests -----------------------------------------------------------------

///|
test "decompress zlib: abc" {
  let data = b"\x78\x9c\x4b\x4c\x4a\x06\x00\x02\x4d\x01\x27"
  let (out, checksum) = decompress(data, Format::Zlib)
  inspect(out, content="[b'\\x61', b'\\x62', b'\\x63']")
  // 0x024D0127 matches Python zlib for "abc".
  inspect(checksum, content="Some(38600999)")
}

///|
test "decompress zlib: hello world" {
  let data = b"\x78\x9c\xcb\x48\xcd\xc9\xc9\x57\x28\xcf\x2f\xca\x49\x01\x00\x1a\x0b\x04\x5d"
  let (out, checksum) = decompress(data, Format::Zlib)
  inspect(
    out,
    content="[b'\\x68', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F', b'\\x20', b'\\x77', b'\\x6F', b'\\x72', b'\\x6C', b'\\x64']",
  )
  inspect(checksum, content="Some(436929629)")
}

///|
fn bytes_prefix_eq(expected : Bytes, buf : Array[Byte], n : Int) -> Bool {
  if n != expected.length() {
    return false
  }
  if n > buf.length() {
    return false
  }
  for i in 0..<n {
    if buf[i] != expected[i] {
      return false
    }
  }
  true
}

///|
test "Decoder.stream_into_buf writes into fixed buffer" {
  let data = b"\x78\x9c\xcb\x48\xcd\xc9\xc9\x57\x28\xcf\x2f\xca\x49\x01\x00\x1a\x0b\x04\x5d"
  let expected = b"hello world"
  let buf : Array[Byte] = []
  for _ in 0..<11 {
    buf.push(b'\x00')
  }
  let decoder = Decoder::new()
  decoder.set_format(Format::Zlib)
  let stream = decoder.stream_into_buf(buf)
  stream.write(data)
  let (written, checksum) = stream.finish()
  inspect(written, content="11")
  inspect(bytes_prefix_eq(expected, buf, 11), content="true")
  inspect(checksum, content="Some(436929629)")
}

///|
test "Decoder.stream_into_buf overflows when buffer is too small" {
  let data = b"\x78\x9c\xcb\x48\xcd\xc9\xc9\x57\x28\xcf\x2f\xca\x49\x01\x00\x1a\x0b\x04\x5d"
  let buf : Array[Byte] = []
  for _ in 0..<5 {
    buf.push(b'\x00')
  }
  let decoder = Decoder::new()
  decoder.set_format(Format::Zlib)
  let stream = decoder.stream_into_buf(buf)
  let ok = try {
    stream.write(data)
    stream.finish() |> ignore
    false
  } catch {
    YaziError::Overflow => true
    _ => false
  }
  inspect(ok, content="true")
}
