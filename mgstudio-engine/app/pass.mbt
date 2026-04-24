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

///|
priv enum ScheduleBuildPassKind {
  AutoInsertApplyDeferredPass
}

///|
fn[W] schedule_run_build_passes(
  schedule_entry : ScheduleEntry[W],
  graph : ScheduleBuildPassGraph,
  base_system_order : Array[Int],
  base_system_edges : Array[(Int, Int, Bool)],
  system_accesses : Array[SystemAccess],
  runnable_mask : Array[Bool],
) -> Unit {
  for pass_kind in schedule_entry.build_passes {
    match pass_kind {
      AutoInsertApplyDeferredPass =>
        schedule_auto_insert_apply_deferred_pass(
          schedule_entry,
          graph,
          base_system_order,
          base_system_edges,
          system_accesses,
          runnable_mask,
        )
    }
  }
}
