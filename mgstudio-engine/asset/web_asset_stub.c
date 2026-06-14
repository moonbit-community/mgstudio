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

#if defined(MGSTUDIO_ENABLE_LIBCURL)
#include <curl/curl.h>
#include <dlfcn.h>

typedef struct {
  int loaded;
  void *handle;
  CURLcode (*global_init)(long flags);
  CURL *(*easy_init)(void);
  CURLcode (*easy_setopt)(CURL *curl, CURLoption option, ...);
  CURLcode (*easy_perform)(CURL *curl);
  CURLcode (*easy_getinfo)(CURL *curl, CURLINFO info, ...);
  void (*easy_cleanup)(CURL *curl);
} mgstudio_curl_api_t;

static mgstudio_curl_api_t *mgstudio_asset_curl_api(void) {
  static mgstudio_curl_api_t api = {0};
  if (api.loaded) {
    return api.handle == NULL ? NULL : &api;
  }
  api.loaded = 1;

  const char *candidates[] = {
#if defined(__APPLE__)
      "/usr/lib/libcurl.4.dylib",
      "libcurl.4.dylib",
      "libcurl.dylib",
#else
      "libcurl.so.4",
      "libcurl.so",
#endif
  };
  for (size_t i = 0; i < sizeof(candidates) / sizeof(candidates[0]); ++i) {
    api.handle = dlopen(candidates[i], RTLD_LAZY | RTLD_LOCAL);
    if (api.handle != NULL) {
      break;
    }
  }
  if (api.handle == NULL) {
    return NULL;
  }

  api.global_init = (CURLcode(*)(long))dlsym(api.handle, "curl_global_init");
  api.easy_init = (CURL * (*)(void))dlsym(api.handle, "curl_easy_init");
  api.easy_setopt =
      (CURLcode(*)(CURL *, CURLoption, ...))dlsym(api.handle, "curl_easy_setopt");
  api.easy_perform =
      (CURLcode(*)(CURL *))dlsym(api.handle, "curl_easy_perform");
  api.easy_getinfo =
      (CURLcode(*)(CURL *, CURLINFO, ...))dlsym(api.handle, "curl_easy_getinfo");
  api.easy_cleanup = (void (*)(CURL *))dlsym(api.handle, "curl_easy_cleanup");
  if (api.global_init == NULL || api.easy_init == NULL ||
      api.easy_setopt == NULL || api.easy_perform == NULL ||
      api.easy_getinfo == NULL || api.easy_cleanup == NULL) {
    dlclose(api.handle);
    api.handle = NULL;
    return NULL;
  }
  return &api;
}

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
  mgstudio_curl_api_t *api = mgstudio_asset_curl_api();
  if (api == NULL) {
    return moonbit_make_bytes(0, 0);
  }

  static int curl_initialized = 0;
  if (!curl_initialized) {
    if (api->global_init(CURL_GLOBAL_DEFAULT) != CURLE_OK) {
      return moonbit_make_bytes(0, 0);
    }
    curl_initialized = 1;
  }

  CURL *curl = api->easy_init();
  if (curl == NULL) {
    return moonbit_make_bytes(0, 0);
  }

  mgstudio_http_buffer_t buffer = {0};
  char *url_cstr = mgstudio_asset_ascii_cstring(url);
  if (url_cstr == NULL) {
    api->easy_cleanup(curl);
    return moonbit_make_bytes(0, 0);
  }

  api->easy_setopt(curl, CURLOPT_URL, url_cstr);
  api->easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
  api->easy_setopt(curl, CURLOPT_FAILONERROR, 1L);
  api->easy_setopt(curl, CURLOPT_ACCEPT_ENCODING, "");
  api->easy_setopt(curl, CURLOPT_USERAGENT, "mgstudio-web-asset/1.0");
  api->easy_setopt(curl, CURLOPT_WRITEFUNCTION, mgstudio_asset_http_write_cb);
  api->easy_setopt(curl, CURLOPT_WRITEDATA, &buffer);

  CURLcode result = api->easy_perform(curl);
  long response_code = 0;
  api->easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);

  free(url_cstr);
  api->easy_cleanup(curl);

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

MOONBIT_FFI_EXPORT int32_t mgstudio_asset_http_supported(void) {
  return mgstudio_asset_curl_api() == NULL ? 0 : 1;
}

#else

MOONBIT_FFI_EXPORT moonbit_bytes_t
mgstudio_asset_http_fetch(moonbit_bytes_t url) {
  (void)url;
  return moonbit_make_bytes(0, 0);
}

MOONBIT_FFI_EXPORT int32_t mgstudio_asset_http_supported(void) { return 0; }

#endif
