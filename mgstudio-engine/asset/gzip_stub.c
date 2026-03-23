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

#include <moonbit.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

MOONBIT_FFI_EXPORT moonbit_bytes_t
mgstudio_asset_gzip_decompress(moonbit_bytes_t input) {
  const uint32_t input_len = Moonbit_array_length(input);
  if (input_len == 0) {
    return moonbit_make_bytes(0, 0);
  }

  z_stream stream;
  memset(&stream, 0, sizeof(stream));
  stream.next_in = input;
  stream.avail_in = (uInt)input_len;

  if (inflateInit2(&stream, 16 + MAX_WBITS) != Z_OK) {
    return moonbit_make_bytes(0, 0);
  }

  size_t capacity = input_len * 4u;
  if (capacity < 4096u) {
    capacity = 4096u;
  }
  uint8_t *buffer = (uint8_t *)malloc(capacity);
  if (buffer == NULL) {
    inflateEnd(&stream);
    return moonbit_make_bytes(0, 0);
  }

  int status = Z_OK;
  while (status == Z_OK) {
    if ((size_t)stream.total_out == capacity) {
      size_t next_capacity = capacity * 2u;
      uint8_t *grown = (uint8_t *)realloc(buffer, next_capacity);
      if (grown == NULL) {
        free(buffer);
        inflateEnd(&stream);
        return moonbit_make_bytes(0, 0);
      }
      buffer = grown;
      capacity = next_capacity;
    }

    stream.next_out = buffer + stream.total_out;
    stream.avail_out = (uInt)(capacity - (size_t)stream.total_out);
    status = inflate(&stream, Z_NO_FLUSH);
  }

  if (status != Z_STREAM_END) {
    free(buffer);
    inflateEnd(&stream);
    return moonbit_make_bytes(0, 0);
  }

  inflateEnd(&stream);
  moonbit_bytes_t output = moonbit_make_bytes((int32_t)stream.total_out, 0);
  if (stream.total_out > 0) {
    memcpy(output, buffer, (size_t)stream.total_out);
  }
  free(buffer);
  return output;
}
