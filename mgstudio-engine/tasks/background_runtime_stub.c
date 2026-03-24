#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "moonbit.h"

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <errno.h>
#include <pthread.h>
#include <time.h>
#endif

MOONBIT_FFI_EXPORT int64_t mgstudio_tasks_now_millis(void) {
#if defined(_WIN32)
  return (int64_t)GetTickCount64();
#else
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (int64_t)ts.tv_sec * 1000LL + (int64_t)ts.tv_nsec / 1000000LL;
#endif
}

typedef struct mgstudio_tasks_mutex_t {
#if defined(_WIN32)
  CRITICAL_SECTION cs;
#else
  pthread_mutex_t mu;
#endif
} mgstudio_tasks_mutex_t;

typedef struct mgstudio_tasks_signal_t {
#if defined(_WIN32)
  HANDLE sem;
#else
  pthread_mutex_t mu;
  pthread_cond_t cv;
  int32_t count;
#endif
} mgstudio_tasks_signal_t;

typedef struct mgstudio_tasks_thread_t {
#if defined(_WIN32)
  HANDLE handle;
#else
  pthread_t thread;
#endif
  int started;
  int detached;
  int joined;
  void (*call_entry)(void *);
  void *entry;
} mgstudio_tasks_thread_t;

static void mgstudio_tasks_mutex_finalize(void *self_raw) {
  mgstudio_tasks_mutex_t *self = (mgstudio_tasks_mutex_t *)self_raw;
  if (self == NULL) {
    return;
  }
#if defined(_WIN32)
  DeleteCriticalSection(&self->cs);
#else
  pthread_mutex_destroy(&self->mu);
#endif
}

MOONBIT_FFI_EXPORT mgstudio_tasks_mutex_t *mgstudio_tasks_mutex_new(void) {
  mgstudio_tasks_mutex_t *self =
      (mgstudio_tasks_mutex_t *)moonbit_make_external_object(
          mgstudio_tasks_mutex_finalize, (uint32_t)sizeof(*self));
#if defined(_WIN32)
  InitializeCriticalSection(&self->cs);
#else
  pthread_mutex_init(&self->mu, NULL);
#endif
  return self;
}

MOONBIT_FFI_EXPORT void mgstudio_tasks_mutex_lock(
    mgstudio_tasks_mutex_t *self) {
  if (self == NULL) {
    return;
  }
#if defined(_WIN32)
  EnterCriticalSection(&self->cs);
#else
  pthread_mutex_lock(&self->mu);
#endif
}

MOONBIT_FFI_EXPORT void mgstudio_tasks_mutex_unlock(
    mgstudio_tasks_mutex_t *self) {
  if (self == NULL) {
    return;
  }
#if defined(_WIN32)
  LeaveCriticalSection(&self->cs);
#else
  pthread_mutex_unlock(&self->mu);
#endif
}

static void mgstudio_tasks_signal_finalize(void *self_raw) {
  mgstudio_tasks_signal_t *self = (mgstudio_tasks_signal_t *)self_raw;
  if (self == NULL) {
    return;
  }
#if defined(_WIN32)
  if (self->sem != NULL) {
    CloseHandle(self->sem);
    self->sem = NULL;
  }
#else
  pthread_cond_destroy(&self->cv);
  pthread_mutex_destroy(&self->mu);
#endif
}

MOONBIT_FFI_EXPORT mgstudio_tasks_signal_t *mgstudio_tasks_signal_new(void) {
  mgstudio_tasks_signal_t *self =
      (mgstudio_tasks_signal_t *)moonbit_make_external_object(
          mgstudio_tasks_signal_finalize, (uint32_t)sizeof(*self));
  memset(self, 0, sizeof(*self));
#if defined(_WIN32)
  self->sem = CreateSemaphoreW(NULL, 0, 0x7fffffff, NULL);
  if (self->sem == NULL) {
    abort();
  }
#else
  pthread_mutex_init(&self->mu, NULL);
  pthread_cond_init(&self->cv, NULL);
  self->count = 0;
#endif
  return self;
}

MOONBIT_FFI_EXPORT void mgstudio_tasks_signal_wake(
    mgstudio_tasks_signal_t *self) {
  if (self == NULL) {
    return;
  }
#if defined(_WIN32)
  ReleaseSemaphore(self->sem, 1, NULL);
#else
  pthread_mutex_lock(&self->mu);
  self->count += 1;
  pthread_cond_signal(&self->cv);
  pthread_mutex_unlock(&self->mu);
#endif
}

MOONBIT_FFI_EXPORT int32_t mgstudio_tasks_signal_try_wait(
    mgstudio_tasks_signal_t *self) {
  if (self == NULL) {
    return 0;
  }
#if defined(_WIN32)
  return WaitForSingleObject(self->sem, 0) == WAIT_OBJECT_0;
#else
  int32_t ok = 0;
  pthread_mutex_lock(&self->mu);
  if (self->count > 0) {
    self->count -= 1;
    ok = 1;
  }
  pthread_mutex_unlock(&self->mu);
  return ok;
#endif
}

MOONBIT_FFI_EXPORT int32_t mgstudio_tasks_signal_wait(
    mgstudio_tasks_signal_t *self,
    int32_t timeout_ms) {
  if (self == NULL) {
    return 0;
  }
#if defined(_WIN32)
  DWORD timeout = timeout_ms < 0 ? INFINITE : (DWORD)timeout_ms;
  return WaitForSingleObject(self->sem, timeout) == WAIT_OBJECT_0;
#else
  int32_t ok = 0;
  pthread_mutex_lock(&self->mu);
  if (timeout_ms < 0) {
    while (self->count == 0) {
      pthread_cond_wait(&self->cv, &self->mu);
    }
    self->count -= 1;
    ok = 1;
  } else if (timeout_ms == 0) {
    if (self->count > 0) {
      self->count -= 1;
      ok = 1;
    }
  } else {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    int64_t nsec =
        (int64_t)ts.tv_nsec + (int64_t)(timeout_ms % 1000) * 1000000LL;
    ts.tv_sec += (time_t)(timeout_ms / 1000) + (time_t)(nsec / 1000000000LL);
    ts.tv_nsec = (long)(nsec % 1000000000LL);
    while (self->count == 0) {
      int rc = pthread_cond_timedwait(&self->cv, &self->mu, &ts);
      if (rc == ETIMEDOUT) {
        break;
      }
    }
    if (self->count > 0) {
      self->count -= 1;
      ok = 1;
    }
  }
  pthread_mutex_unlock(&self->mu);
  return ok;
#endif
}

#if defined(_WIN32)
static DWORD WINAPI mgstudio_tasks_thread_main(LPVOID self_raw) {
  mgstudio_tasks_thread_t *self = (mgstudio_tasks_thread_t *)self_raw;
#else
static void *mgstudio_tasks_thread_main(void *self_raw) {
  mgstudio_tasks_thread_t *self = (mgstudio_tasks_thread_t *)self_raw;
#endif
  if (self != NULL && self->call_entry != NULL) {
    void (*call_entry)(void *) = self->call_entry;
    void *entry = self->entry;
    self->call_entry = NULL;
    self->entry = NULL;
    call_entry(entry);
    moonbit_decref(call_entry);
    moonbit_decref(entry);
  }
#if defined(_WIN32)
  return 0;
#else
  return NULL;
#endif
}

static void mgstudio_tasks_thread_finalize(void *self_raw) {
  mgstudio_tasks_thread_t *self = (mgstudio_tasks_thread_t *)self_raw;
  if (self == NULL) {
    return;
  }

  if (self->started && !self->detached && !self->joined) {
#if defined(_WIN32)
    WaitForSingleObject(self->handle, INFINITE);
    CloseHandle(self->handle);
    self->handle = NULL;
#else
    pthread_join(self->thread, NULL);
#endif
    self->joined = 1;
  }

  if (!self->started && self->call_entry != NULL) {
    moonbit_decref(self->call_entry);
    self->call_entry = NULL;
  }
  if (!self->started && self->entry != NULL) {
    moonbit_decref(self->entry);
    self->entry = NULL;
  }
}

MOONBIT_FFI_EXPORT mgstudio_tasks_thread_t *mgstudio_tasks_thread_spawn(
    void (*call_entry)(void *),
    void *entry) {
  mgstudio_tasks_thread_t *self =
      (mgstudio_tasks_thread_t *)moonbit_make_external_object(
          mgstudio_tasks_thread_finalize, (uint32_t)sizeof(*self));
  memset(self, 0, sizeof(*self));
  self->call_entry = call_entry;
  self->entry = entry;

#if defined(_WIN32)
  self->handle = CreateThread(NULL, 0, mgstudio_tasks_thread_main, self, 0, NULL);
  if (self->handle == NULL) {
    abort();
  }
#else
  if (pthread_create(&self->thread, NULL, mgstudio_tasks_thread_main, self) !=
      0) {
    abort();
  }
#endif
  self->started = 1;
  return self;
}

MOONBIT_FFI_EXPORT void mgstudio_tasks_thread_join(
    mgstudio_tasks_thread_t *self) {
  if (self == NULL || !self->started || self->detached || self->joined) {
    return;
  }
#if defined(_WIN32)
  WaitForSingleObject(self->handle, INFINITE);
  CloseHandle(self->handle);
  self->handle = NULL;
#else
  pthread_join(self->thread, NULL);
#endif
  self->joined = 1;
}

MOONBIT_FFI_EXPORT void mgstudio_tasks_thread_detach(
    mgstudio_tasks_thread_t *self) {
  if (self == NULL || !self->started || self->detached || self->joined) {
    return;
  }
#if defined(_WIN32)
  CloseHandle(self->handle);
  self->handle = NULL;
#else
  pthread_detach(self->thread);
#endif
  self->detached = 1;
}
