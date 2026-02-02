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
fn make_cli_parser() -> @clap.Parser {
  @clap.Parser::new(
    prog="mgstudio",
    description="mgstudio developer CLI (codegen/build/run entrypoint).",
    subcmds={
      "gen": @clap.SubCommand::new(
        help="Generate ecs.g.mbt from #ecs.component / #ecs.resource.",
        args={
          "check": @clap.Arg::flag(
            short='c',
            help="Verify generated files are up-to-date (do not write).",
          ),
          "verbose": @clap.Arg::flag(
            short='v',
            help="Print scanned modules and generated paths.",
          ),
        },
      ),
      "run": @clap.SubCommand::new(
        help="Run a game described by a game config file in native runtime (calls export `game_app`).",
        args={
          "game": @clap.Arg::named(
            short='g',
            nargs=@clap.Nargs::AtMost(1U),
            help="Path to game config file. If omitted, search for ./moon.game.json from current directory upwards.",
          ),
          "backend": @clap.Arg::named(
            nargs=@clap.Nargs::AtMost(1U),
            help="Native backend: wasmoon (default) | wasmtime (Rust).",
          ),
        },
      ),
      "serve": @clap.SubCommand::new(
        help="Serve the web runtime and run a game described by a game config file in browser (calls export `game_app`).",
        args={
          "game": @clap.Arg::named(
            short='g',
            nargs=@clap.Nargs::AtMost(1U),
            help="Path to game config file. If omitted, search for ./moon.game.json from current directory upwards.",
          ),
          "addr": @clap.Arg::named(
            nargs=@clap.Nargs::AtMost(1U),
            help="Override web server bind address (default: from game config or 127.0.0.1).",
          ),
          "port": @clap.Arg::named(
            short='p',
            nargs=@clap.Nargs::AtMost(1U),
            help="Override web server port (default: from game config or 8099).",
          ),
        },
      ),
      "new": @clap.SubCommand::new(
        help="Create a new MoonBit game project (moon new + moon.game.json + index.html).",
        args={
          "name": @clap.Arg::positional(
            nargs=@clap.Nargs::Fixed(1U),
            help="Project name (directory to create).",
          ),
          "local-engine": @clap.Arg::flag(
            help="Use local mgstudio-engine from ../mgstudio-engine (path dependency).",
          ),
        },
      ),
    },
  )
}

///|
fn print_cli_help(parser : @clap.Parser) -> Unit {
  let v = @clap.SimpleValue::new(parser.prog)
  // `-h/--help` triggers `Parser::gen_help_message`.
  let msg_opt : String? = parser.parse(v, ["-h"]) catch {
    _ => Some("Help is unavailable.")
  }
  match msg_opt {
    Some(msg) => println(msg)
    None => println("No help message available.")
  }
}

///|
fn print_subcommand_help(parser : @clap.Parser, name : String) -> Unit {
  let v = @clap.SimpleValue::new(parser.prog)
  let msg_opt : String? = parser.parse(v, [name, "-h"]) catch { _ => None }
  match msg_opt {
    Some(msg) => println(msg)
    None => print_cli_help(parser)
  }
}
