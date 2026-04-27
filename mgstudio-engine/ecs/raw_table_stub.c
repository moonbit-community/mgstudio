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

typedef struct {
  uint64_t *data;
  int32_t len;
  int32_t cap;
} mgstudio_ecs_raw_table_rows_t;

typedef struct {
  int32_t *added_sequences;
  int32_t *changed_sequences;
  int32_t *changed_caller_ids;
  int32_t len;
  int32_t cap;
} mgstudio_ecs_raw_table_metadata_t;

typedef struct {
  void **values;
  int32_t *added_sequences;
  int32_t *changed_sequences;
  int32_t *changed_caller_ids;
  int32_t len;
  int32_t cap;
} mgstudio_ecs_raw_table_value_column_t;

static void mgstudio_ecs_raw_table_rows_finalize(void *ptr) {
  mgstudio_ecs_raw_table_rows_t *rows = (mgstudio_ecs_raw_table_rows_t *)ptr;
  if (rows->data != NULL) {
    free(rows->data);
    rows->data = NULL;
  }
  rows->len = 0;
  rows->cap = 0;
}

static void mgstudio_ecs_raw_table_metadata_finalize(void *ptr) {
  mgstudio_ecs_raw_table_metadata_t *metadata =
    (mgstudio_ecs_raw_table_metadata_t *)ptr;
  if (metadata->added_sequences != NULL) {
    free(metadata->added_sequences);
    metadata->added_sequences = NULL;
  }
  if (metadata->changed_sequences != NULL) {
    free(metadata->changed_sequences);
    metadata->changed_sequences = NULL;
  }
  if (metadata->changed_caller_ids != NULL) {
    free(metadata->changed_caller_ids);
    metadata->changed_caller_ids = NULL;
  }
  metadata->len = 0;
  metadata->cap = 0;
}

static void mgstudio_ecs_raw_table_value_column_finalize(void *ptr) {
  mgstudio_ecs_raw_table_value_column_t *column =
    (mgstudio_ecs_raw_table_value_column_t *)ptr;
  if (column->values != NULL) {
    for (int32_t i = 0; i < column->len; i += 1) {
      if (column->values[i] != NULL) {
        moonbit_decref(column->values[i]);
        column->values[i] = NULL;
      }
    }
    free(column->values);
    column->values = NULL;
  }
  if (column->added_sequences != NULL) {
    free(column->added_sequences);
    column->added_sequences = NULL;
  }
  if (column->changed_sequences != NULL) {
    free(column->changed_sequences);
    column->changed_sequences = NULL;
  }
  if (column->changed_caller_ids != NULL) {
    free(column->changed_caller_ids);
    column->changed_caller_ids = NULL;
  }
  column->len = 0;
  column->cap = 0;
}

static int mgstudio_ecs_raw_table_rows_reserve(
  mgstudio_ecs_raw_table_rows_t *rows,
  int32_t min_cap
) {
  if (rows->cap >= min_cap) {
    return 1;
  }
  int32_t next_cap = rows->cap > 0 ? rows->cap : 4;
  while (next_cap < min_cap) {
    if (next_cap > INT32_MAX / 2) {
      next_cap = min_cap;
      break;
    }
    next_cap *= 2;
  }
  uint64_t *grown =
    (uint64_t *)realloc(rows->data, (size_t)next_cap * sizeof(uint64_t));
  if (grown == NULL) {
    return 0;
  }
  rows->data = grown;
  rows->cap = next_cap;
  return 1;
}

static int mgstudio_ecs_raw_table_metadata_reserve(
  mgstudio_ecs_raw_table_metadata_t *metadata,
  int32_t min_cap
) {
  if (metadata->cap >= min_cap) {
    return 1;
  }
  int32_t next_cap = metadata->cap > 0 ? metadata->cap : 4;
  while (next_cap < min_cap) {
    if (next_cap > INT32_MAX / 2) {
      next_cap = min_cap;
      break;
    }
    next_cap *= 2;
  }
  int32_t *old_added = metadata->added_sequences;
  int32_t *old_changed = metadata->changed_sequences;
  int32_t *old_caller_ids = metadata->changed_caller_ids;
  int32_t *grown_added = (int32_t *)realloc(
    old_added,
    (size_t)next_cap * sizeof(int32_t)
  );
  if (grown_added == NULL) {
    return 0;
  }
  int32_t *grown_changed = (int32_t *)realloc(
    old_changed,
    (size_t)next_cap * sizeof(int32_t)
  );
  if (grown_changed == NULL) {
    if (grown_added != old_added) {
      free(grown_added);
    }
    return 0;
  }
  int32_t *grown_caller_ids = (int32_t *)realloc(
    old_caller_ids,
    (size_t)next_cap * sizeof(int32_t)
  );
  if (grown_caller_ids == NULL) {
    if (grown_added != old_added) {
      free(grown_added);
    }
    if (grown_changed != old_changed) {
      free(grown_changed);
    }
    return 0;
  }
  metadata->added_sequences = grown_added;
  metadata->changed_sequences = grown_changed;
  metadata->changed_caller_ids = grown_caller_ids;
  metadata->cap = next_cap;
  return 1;
}

static int mgstudio_ecs_raw_table_value_column_reserve(
  mgstudio_ecs_raw_table_value_column_t *column,
  int32_t min_cap
) {
  if (column->cap >= min_cap) {
    return 1;
  }
  int32_t next_cap = column->cap > 0 ? column->cap : 4;
  while (next_cap < min_cap) {
    if (next_cap > INT32_MAX / 2) {
      next_cap = min_cap;
      break;
    }
    next_cap *= 2;
  }
  void **next_values =
    (void **)malloc((size_t)next_cap * sizeof(void *));
  int32_t *next_added =
    (int32_t *)malloc((size_t)next_cap * sizeof(int32_t));
  int32_t *next_changed =
    (int32_t *)malloc((size_t)next_cap * sizeof(int32_t));
  int32_t *next_caller_ids =
    (int32_t *)malloc((size_t)next_cap * sizeof(int32_t));
  if (
    next_values == NULL ||
    next_added == NULL ||
    next_changed == NULL ||
    next_caller_ids == NULL
  ) {
    free(next_values);
    free(next_added);
    free(next_changed);
    free(next_caller_ids);
    return 0;
  }
  for (int32_t i = 0; i < column->len; i += 1) {
    next_values[i] = column->values[i];
    next_added[i] = column->added_sequences[i];
    next_changed[i] = column->changed_sequences[i];
    next_caller_ids[i] = column->changed_caller_ids[i];
  }
  for (int32_t i = column->len; i < next_cap; i += 1) {
    next_values[i] = NULL;
    next_added[i] = -1;
    next_changed[i] = -1;
    next_caller_ids[i] = 0;
  }
  free(column->values);
  free(column->added_sequences);
  free(column->changed_sequences);
  free(column->changed_caller_ids);
  column->values = next_values;
  column->added_sequences = next_added;
  column->changed_sequences = next_changed;
  column->changed_caller_ids = next_caller_ids;
  column->cap = next_cap;
  return 1;
}

MOONBIT_FFI_EXPORT
mgstudio_ecs_raw_table_rows_t *mgstudio_ecs_raw_table_rows_new(void) {
  mgstudio_ecs_raw_table_rows_t *rows =
    (mgstudio_ecs_raw_table_rows_t *)moonbit_make_external_object(
      mgstudio_ecs_raw_table_rows_finalize,
      (uint32_t)sizeof(mgstudio_ecs_raw_table_rows_t)
    );
  rows->data = NULL;
  rows->len = 0;
  rows->cap = 0;
  return rows;
}

MOONBIT_FFI_EXPORT
mgstudio_ecs_raw_table_value_column_t *mgstudio_ecs_raw_table_value_column_new(
  void
) {
  mgstudio_ecs_raw_table_value_column_t *column =
    (mgstudio_ecs_raw_table_value_column_t *)moonbit_make_external_object(
      mgstudio_ecs_raw_table_value_column_finalize,
      (uint32_t)sizeof(mgstudio_ecs_raw_table_value_column_t)
    );
  column->values = NULL;
  column->added_sequences = NULL;
  column->changed_sequences = NULL;
  column->changed_caller_ids = NULL;
  column->len = 0;
  column->cap = 0;
  return column;
}

MOONBIT_FFI_EXPORT
mgstudio_ecs_raw_table_metadata_t *mgstudio_ecs_raw_table_metadata_new(void) {
  mgstudio_ecs_raw_table_metadata_t *metadata =
    (mgstudio_ecs_raw_table_metadata_t *)moonbit_make_external_object(
      mgstudio_ecs_raw_table_metadata_finalize,
      (uint32_t)sizeof(mgstudio_ecs_raw_table_metadata_t)
    );
  metadata->added_sequences = NULL;
  metadata->changed_sequences = NULL;
  metadata->changed_caller_ids = NULL;
  metadata->len = 0;
  metadata->cap = 0;
  return metadata;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_rows_len(
  mgstudio_ecs_raw_table_rows_t *rows
) {
  return rows != NULL ? rows->len : 0;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_metadata_len(
  mgstudio_ecs_raw_table_metadata_t *metadata
) {
  return metadata != NULL ? metadata->len : 0;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_value_column_len(
  mgstudio_ecs_raw_table_value_column_t *column
) {
  return column != NULL ? column->len : 0;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_rows_push(
  mgstudio_ecs_raw_table_rows_t *rows,
  uint64_t entity_bits
) {
  if (rows == NULL) {
    return -1;
  }
  if (!mgstudio_ecs_raw_table_rows_reserve(rows, rows->len + 1)) {
    return -1;
  }
  rows->data[rows->len] = entity_bits;
  rows->len += 1;
  return rows->len - 1;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_metadata_push(
  mgstudio_ecs_raw_table_metadata_t *metadata,
  int32_t added_sequence,
  int32_t changed_sequence,
  int32_t changed_caller_id
) {
  if (metadata == NULL) {
    return 0;
  }
  if (!mgstudio_ecs_raw_table_metadata_reserve(metadata, metadata->len + 1)) {
    return 0;
  }
  metadata->added_sequences[metadata->len] = added_sequence;
  metadata->changed_sequences[metadata->len] = changed_sequence;
  metadata->changed_caller_ids[metadata->len] = changed_caller_id;
  metadata->len += 1;
  return 1;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_value_column_push(
  mgstudio_ecs_raw_table_value_column_t *column,
  void *value,
  int32_t added_sequence,
  int32_t changed_sequence,
  int32_t changed_caller_id
) {
  if (column == NULL || value == NULL) {
    return 0;
  }
  if (!mgstudio_ecs_raw_table_value_column_reserve(column, column->len + 1)) {
    return 0;
  }
  moonbit_incref(value);
  column->values[column->len] = value;
  column->added_sequences[column->len] = added_sequence;
  column->changed_sequences[column->len] = changed_sequence;
  column->changed_caller_ids[column->len] = changed_caller_id;
  column->len += 1;
  return 1;
}

MOONBIT_FFI_EXPORT
uint64_t mgstudio_ecs_raw_table_rows_get(
  mgstudio_ecs_raw_table_rows_t *rows,
  int32_t row
) {
  if (rows == NULL || row < 0 || row >= rows->len) {
    return 0;
  }
  return rows->data[row];
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_metadata_set(
  mgstudio_ecs_raw_table_metadata_t *metadata,
  int32_t row,
  int32_t added_sequence,
  int32_t changed_sequence,
  int32_t changed_caller_id
) {
  if (metadata == NULL || row < 0 || row >= metadata->len) {
    return 0;
  }
  metadata->added_sequences[row] = added_sequence;
  metadata->changed_sequences[row] = changed_sequence;
  metadata->changed_caller_ids[row] = changed_caller_id;
  return 1;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_value_column_set_metadata(
  mgstudio_ecs_raw_table_value_column_t *column,
  int32_t row,
  int32_t added_sequence,
  int32_t changed_sequence,
  int32_t changed_caller_id
) {
  if (column == NULL || row < 0 || row >= column->len) {
    return 0;
  }
  column->added_sequences[row] = added_sequence;
  column->changed_sequences[row] = changed_sequence;
  column->changed_caller_ids[row] = changed_caller_id;
  return 1;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_value_column_set_changed(
  mgstudio_ecs_raw_table_value_column_t *column,
  int32_t row,
  int32_t changed_sequence,
  int32_t changed_caller_id
) {
  if (column == NULL || row < 0 || row >= column->len) {
    return 0;
  }
  column->changed_sequences[row] = changed_sequence;
  column->changed_caller_ids[row] = changed_caller_id;
  return 1;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_value_column_replace(
  mgstudio_ecs_raw_table_value_column_t *column,
  int32_t row,
  void *value
) {
  if (column == NULL || value == NULL || row < 0 || row >= column->len) {
    return 0;
  }
  moonbit_incref(value);
  if (column->values[row] != NULL) {
    moonbit_decref(column->values[row]);
  }
  column->values[row] = value;
  return 1;
}

MOONBIT_FFI_EXPORT
void *mgstudio_ecs_raw_table_value_column_value(
  mgstudio_ecs_raw_table_value_column_t *column,
  int32_t row
) {
  if (column == NULL || row < 0 || row >= column->len) {
    return NULL;
  }
  void *value = column->values[row];
  if (value != NULL) {
    moonbit_incref(value);
  }
  return value;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_value_column_append_from_row(
  mgstudio_ecs_raw_table_value_column_t *dst,
  mgstudio_ecs_raw_table_value_column_t *src,
  int32_t row
) {
  if (dst == NULL || src == NULL || row < 0 || row >= src->len) {
    return 0;
  }
  return mgstudio_ecs_raw_table_value_column_push(
    dst,
    src->values[row],
    -1,
    -1,
    0
  );
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_metadata_added(
  mgstudio_ecs_raw_table_metadata_t *metadata,
  int32_t row
) {
  if (metadata == NULL || row < 0 || row >= metadata->len) {
    return -1;
  }
  return metadata->added_sequences[row];
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_value_column_added(
  mgstudio_ecs_raw_table_value_column_t *column,
  int32_t row
) {
  if (column == NULL || row < 0 || row >= column->len) {
    return -1;
  }
  return column->added_sequences[row];
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_metadata_changed(
  mgstudio_ecs_raw_table_metadata_t *metadata,
  int32_t row
) {
  if (metadata == NULL || row < 0 || row >= metadata->len) {
    return -1;
  }
  return metadata->changed_sequences[row];
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_value_column_changed(
  mgstudio_ecs_raw_table_value_column_t *column,
  int32_t row
) {
  if (column == NULL || row < 0 || row >= column->len) {
    return -1;
  }
  return column->changed_sequences[row];
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_metadata_changed_caller_id(
  mgstudio_ecs_raw_table_metadata_t *metadata,
  int32_t row
) {
  if (metadata == NULL || row < 0 || row >= metadata->len) {
    return 0;
  }
  return metadata->changed_caller_ids[row];
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_value_column_changed_caller_id(
  mgstudio_ecs_raw_table_value_column_t *column,
  int32_t row
) {
  if (column == NULL || row < 0 || row >= column->len) {
    return 0;
  }
  return column->changed_caller_ids[row];
}

MOONBIT_FFI_EXPORT
void mgstudio_ecs_raw_table_rows_swap_remove(
  mgstudio_ecs_raw_table_rows_t *rows,
  int32_t row
) {
  if (rows == NULL || row < 0 || row >= rows->len) {
    return;
  }
  int32_t last_index = rows->len - 1;
  if (row != last_index) {
    rows->data[row] = rows->data[last_index];
  }
  rows->len = last_index;
  if (rows->len == 0 && rows->data != NULL) {
    memset(rows->data, 0, sizeof(uint64_t));
  }
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_metadata_swap_remove(
  mgstudio_ecs_raw_table_metadata_t *metadata,
  int32_t row
) {
  if (metadata == NULL || row < 0 || row >= metadata->len) {
    return 0;
  }
  int32_t last_index = metadata->len - 1;
  if (row != last_index) {
    metadata->added_sequences[row] = metadata->added_sequences[last_index];
    metadata->changed_sequences[row] = metadata->changed_sequences[last_index];
    metadata->changed_caller_ids[row] =
      metadata->changed_caller_ids[last_index];
  }
  metadata->len = last_index;
  return 1;
}

MOONBIT_FFI_EXPORT
int32_t mgstudio_ecs_raw_table_value_column_swap_remove(
  mgstudio_ecs_raw_table_value_column_t *column,
  int32_t row
) {
  if (column == NULL || row < 0 || row >= column->len) {
    return 0;
  }
  int32_t last_index = column->len - 1;
  if (column->values[row] != NULL) {
    moonbit_decref(column->values[row]);
  }
  if (row != last_index) {
    column->values[row] = column->values[last_index];
    column->added_sequences[row] = column->added_sequences[last_index];
    column->changed_sequences[row] = column->changed_sequences[last_index];
    column->changed_caller_ids[row] = column->changed_caller_ids[last_index];
  }
  column->values[last_index] = NULL;
  column->added_sequences[last_index] = -1;
  column->changed_sequences[last_index] = -1;
  column->changed_caller_ids[last_index] = 0;
  column->len = last_index;
  return 1;
}
