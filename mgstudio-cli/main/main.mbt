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
/// mgstudio CLI entrypoint.
///
/// Currently supported:
/// - `mgstudio gen`: generate `ecs.g.mbt` per package for `#ecs.component` / `#ecs.resource`.
/// - `mgstudio run`: run a game config in native runtime (calls `game_app`).
/// - `mgstudio serve`: serve the web runtime and run a game config in browser (calls `game_app`).
/// - `mgstudio new`: create a new game project template.
async fn main {
  let argv = @sys.get_cli_args()
  let parser = make_cli_parser()
  let value = @clap.SimpleValue::new(parser.prog)
  let args : Array[String] = []
  for i in 1..<argv.length() {
    args.push(argv[i])
  }
  let normalized_args = args

  // Let clap generate and format help output.
  if normalized_args.length() == 0 {
    print_cli_help(parser)
    @sys.exit(2)
  }
  let help : String? = parser.parse(value, normalized_args) catch {
    err => {
      println(err)
      if normalized_args.length() > 0 {
        let top = normalized_args[0]
        if top == "run" || top == "serve" || top == "gen" || top == "new" {
          print_subcommand_help(parser, top)
        } else {
          print_cli_help(parser)
        }
      } else {
        print_cli_help(parser)
      }
      @sys.exit(2)
      None
    }
  }
  if help is Some(msg) {
    println(msg)
    @sys.exit(0)
  }
  match value.subcmd {
    Some(cmd) =>
      match cmd.name {
        "gen" => cmd_gen(cmd)
        "run" => cmd_run(cmd)
        "serve" => cmd_serve(cmd)
        "new" => cmd_new(cmd)
        _ => {
          println("Unknown command: \{cmd.name}")
          print_cli_help(parser)
          @sys.exit(2)
        }
      }
    None => {
      print_cli_help(parser)
      @sys.exit(2)
    }
  }
}
