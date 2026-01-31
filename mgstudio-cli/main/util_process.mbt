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
async fn run_process_checked(
  cmd : String,
  args : Array[String],
  cwd? : String,
  extra_env? : Map[String, String] = {},
) -> Unit {
  let cwd_str = cwd.unwrap_or("(default)")
  println("Running: \{cmd} \{render_argv(args)} (cwd=\{cwd_str})")
  let code = @process.run(cmd, args, cwd?, extra_env~)
  if code != 0 {
    raise RunError::ProcessFailed("\{cmd} \{render_argv(args)}", code)
  }
}

///|
fn render_argv(args : Array[String]) -> String {
  let mut out = ""
  for i in 0..<args.length() {
    if i > 0 {
      out = out + " "
    }
    out = out + args[i]
  }
  out
}
