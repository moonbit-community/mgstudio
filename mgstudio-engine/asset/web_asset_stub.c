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

#include <curl/curl.h>
#include <moonbit.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  uint8_t *data;
  size_t len;
  size_t cap;
} mgstudio_http_buffer_t;

static char *mgstudio_asset_ascii_cstring(moonbit_bytes_t input) {
  uint32_t len = Moonbit_array_length(input);
  char *output = (char *)malloc((size_t)len + 1u);
  if (output == NULL) {
    return NULL;
  }
  for (uint32_t i = 0; i < len; ++i) {
    uint8_t byte = input[i];
    output[i] = (char)(byte <= 0x7Fu ? byte : '?');
  }
  output[len] = '\0';
  return output;
}

static size_t mgstudio_asset_http_write_cb(
    void *contents, size_t size, size_t nmemb, void *userp) {
  mgstudio_http_buffer_t *buffer = (mgstudio_http_buffer_t *)userp;
  size_t bytes_len = size * nmemb;
  size_t required = buffer->len + bytes_len;
  if (required > buffer->cap) {
    size_t next_cap = buffer->cap == 0 ? 4096u : buffer->cap;
    while (next_cap < required) {
      next_cap *= 2u;
    }
    uint8_t *grown = (uint8_t *)realloc(buffer->data, next_cap);
    if (grown == NULL) {
      return 0;
    }
    buffer->data = grown;
    buffer->cap = next_cap;
  }
  memcpy(buffer->data + buffer->len, contents, bytes_len);
  buffer->len += bytes_len;
  return bytes_len;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t
mgstudio_asset_http_fetch(moonbit_bytes_t url) {
  static int curl_initialized = 0;
  if (!curl_initialized) {
    if (curl_global_init(CURL_GLOBAL_DEFAULT) != CURLE_OK) {
      return moonbit_make_bytes(0, 0);
    }
    curl_initialized = 1;
  }

  CURL *curl = curl_easy_init();
  if (curl == NULL) {
    return moonbit_make_bytes(0, 0);
  }

  mgstudio_http_buffer_t buffer = {0};
  char *url_cstr = mgstudio_asset_ascii_cstring(url);
  if (url_cstr == NULL) {
    curl_easy_cleanup(curl);
    return moonbit_make_bytes(0, 0);
  }

  curl_easy_setopt(curl, CURLOPT_URL, url_cstr);
  curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
  curl_easy_setopt(curl, CURLOPT_FAILONERROR, 1L);
  curl_easy_setopt(curl, CURLOPT_ACCEPT_ENCODING, "");
  curl_easy_setopt(curl, CURLOPT_USERAGENT, "mgstudio-web-asset/1.0");
  curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, mgstudio_asset_http_write_cb);
  curl_easy_setopt(curl, CURLOPT_WRITEDATA, &buffer);

  CURLcode result = curl_easy_perform(curl);
  long response_code = 0;
  curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);

  free(url_cstr);
  curl_easy_cleanup(curl);

  if (result != CURLE_OK || response_code < 200 || response_code >= 300) {
    free(buffer.data);
    return moonbit_make_bytes(0, 0);
  }

  moonbit_bytes_t output = moonbit_make_bytes((int32_t)buffer.len, 0);
  if (buffer.len > 0) {
    memcpy(output, buffer.data, buffer.len);
  }
  free(buffer.data);
  return output;
}
