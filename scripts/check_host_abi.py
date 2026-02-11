#!/usr/bin/env python3
# Copyright 2025 International Digital Economy Academy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import NoReturn


ENGINE_FN_HEADER_RE = re.compile(
    r"(?:pub(?:\([^)]+\))?\s+)?fn\s+[A-Za-z_]\w*\s*\(",
    re.DOTALL,
)

HOST_ASSIGNMENT_RE = re.compile(
    r'=\s*"mgstudio_host"\s*"(?P<name>[A-Za-z_]\w*)"',
    re.DOTALL,
)

TOP_LEVEL_WEB_LET_RE = re.compile(
    r"""
    ^\s{2}let\s+(?P<name>[A-Za-z_]\w*)\s*=\s*(?P<expr>.*?)
    (?=^\s{2}let\s+[A-Za-z_]\w*\s*=|^\s{2}@js\.from_entries|\Z)
    """,
    re.MULTILINE | re.DOTALL | re.VERBOSE,
)


@dataclass
class SourceTable:
    source_name: str
    funcs: dict[str, int]


def fail(message: str) -> NoReturn:
    print(f"[host-abi-check] error: {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_moonbit_param_count(param_text: str) -> int:
    stripped = param_text.strip()
    if stripped == "":
        return 0
    parts = [piece.strip() for piece in stripped.split(",")]
    return len([piece for piece in parts if piece != ""])


def append_func(table: dict[str, int], name: str, arity: int, source_name: str) -> None:
    existing = table.get(name)
    if existing is not None and existing != arity:
        fail(
            f"{source_name}: function '{name}' has inconsistent arity "
            f"({existing} vs {arity})"
        )
    table[name] = arity


def parse_engine_expected(repo_root: Path) -> SourceTable:
    engine_root = repo_root / "mgstudio-engine"
    if not engine_root.is_dir():
        fail(f"missing directory: {engine_root}")
    table: dict[str, int] = {}
    for file_path in sorted(engine_root.rglob("*.mbt")):
        if "/_build/" in file_path.as_posix() or "/.mooncakes/" in file_path.as_posix():
            continue
        source = file_path.read_text(encoding="utf-8")
        for header_match in ENGINE_FN_HEADER_RE.finditer(source):
            open_paren_index = header_match.end() - 1
            close_paren_index = find_balanced_close(
                source, open_paren_index, "(", ")"
            )
            trailing = source[close_paren_index + 1 :]
            host_assignment_match = HOST_ASSIGNMENT_RE.search(trailing)
            if host_assignment_match is None:
                continue
            assignment_offset = host_assignment_match.start()
            first_open_brace_offset = trailing.find("{")
            if first_open_brace_offset >= 0 and first_open_brace_offset < assignment_offset:
                continue
            before_assignment = trailing[:assignment_offset]
            if "->" not in before_assignment:
                continue
            params_text = source[open_paren_index + 1 : close_paren_index]
            host_name = host_assignment_match.group("name")
            arity = parse_moonbit_param_count(params_text)
            append_func(table, host_name, arity, file_path.as_posix())
    return SourceTable("engine(imports)", table)


def iter_call_snippets(source: str, call_token: str) -> list[str]:
    snippets: list[str] = []
    search_index = 0
    token_length = len(call_token)
    while True:
        token_index = source.find(call_token, search_index)
        if token_index < 0:
            break
        open_paren_index = token_index + token_length - 1
        close_paren_index = find_balanced_close(source, open_paren_index, "(", ")")
        snippets.append(source[token_index : close_paren_index + 1])
        search_index = close_paren_index + 1
    return snippets


def parse_native_wasmoon(repo_root: Path) -> SourceTable:
    file_path = repo_root / "mgstudio-runtime/native/host_imports.mbt"
    if not file_path.is_file():
        fail(f"missing file: {file_path}")
    source = file_path.read_text(encoding="utf-8")
    table: dict[str, int] = {}
    for snippet in iter_call_snippets(source, "linker.add_host_func("):
        header_match = re.search(
            r'linker\.add_host_func\(\s*"(?P<module>[^"]+)"\s*,\s*"(?P<name>[^"]+)"',
            snippet,
            re.DOTALL,
        )
        if header_match is None:
            continue
        if header_match.group("module") != "mgstudio_host":
            continue
        params_match = re.search(
            r"func_type\s*=\s*ft\(\s*\[(?P<params>.*?)\]\s*,",
            snippet,
            re.DOTALL,
        )
        if params_match is None:
            fail(f"{file_path}: cannot parse func_type params for {header_match.group('name')}")
        name = header_match.group("name")
        params = params_match.group("params")
        arity = len(re.findall(r"@types\.ValueType::[A-Za-z_]\w*", params))
        append_func(table, name, arity, file_path.as_posix())
    return SourceTable("runtime/native-wasmoon", table)


def parse_native_wasmtime(repo_root: Path) -> SourceTable:
    file_path = repo_root / "mgstudio-runtime/native-wasmtime/src/host.rs"
    if not file_path.is_file():
        fail(f"missing file: {file_path}")
    source = file_path.read_text(encoding="utf-8")
    table: dict[str, int] = {}
    for snippet in iter_call_snippets(source, "define_func("):
        header_match = re.search(
            r'define_func\(\s*store\s*,\s*linker\s*,\s*"(?P<module>[^"]+)"\s*,\s*"(?P<name>[^"]+)"\s*,',
            snippet,
            re.DOTALL,
        )
        if header_match is None:
            continue
        if header_match.group("module") != "mgstudio_host":
            continue
        params_match = re.search(
            r'"\s*,\s*"[^"]+"\s*,\s*&\[(?P<params>.*?)\]\s*,\s*&\[(?P<results>.*?)\]\s*,',
            snippet,
            re.DOTALL,
        )
        if params_match is None:
            fail(f"{file_path}: cannot parse ValType params for {header_match.group('name')}")
        name = header_match.group("name")
        params = params_match.group("params")
        arity = len(re.findall(r"ValType::[A-Za-z_]\w*", params))
        append_func(table, name, arity, file_path.as_posix())

    for name_match in re.finditer(
        r'\(\s*"(?P<name>input_is_(?:key|mouse_button)_[A-Za-z_]\w*)"\s*,\s*\d+\s*\)',
        source,
    ):
        append_func(table, name_match.group("name"), 1, file_path.as_posix())

    for tuple_match in re.finditer(
        r'\(\s*"(?P<name>[A-Za-z_]\w*)"\s*,\s*vec!\[(?P<params>.*?)\]\s*,\s*vec!\[(?P<results>.*?)\]\s*,\s*[-\d]+\s*,?\s*\)',
        source,
        re.DOTALL,
    ):
        arity = len(re.findall(r"ValType::[A-Za-z_]\w*", tuple_match.group("params")))
        append_func(table, tuple_match.group("name"), arity, file_path.as_posix())

    return SourceTable("runtime/native-wasmtime", table)


def find_balanced_close(text: str, open_index: int, open_char: str, close_char: str) -> int:
    depth = 1
    index = open_index + 1
    in_string: str | None = None
    escaping = False
    while index < len(text):
        char = text[index]
        if in_string is not None:
            if escaping:
                escaping = False
            elif char == "\\":
                escaping = True
            elif char == in_string:
                in_string = None
        else:
            if char == '"' or char == "'":
                in_string = char
            elif char == open_char:
                depth += 1
            elif char == close_char:
                depth -= 1
                if depth == 0:
                    return index
        index += 1
    fail(f"unclosed '{open_char}' starting at index {open_index}")


def parse_tuple_content_items(entries_text: str) -> list[str]:
    items: list[str] = []
    index = 0
    while index < len(entries_text):
        while index < len(entries_text) and (
            entries_text[index].isspace() or entries_text[index] == ","
        ):
            index += 1
        if index >= len(entries_text):
            break
        if entries_text[index] != "(":
            fail(
                "web host entries parse failure: expected '(' "
                f"at position {index}, got '{entries_text[index]}'"
            )
        end_index = find_balanced_close(entries_text, index, "(", ")")
        items.append(entries_text[index + 1 : end_index])
        index = end_index + 1
    return items


def infer_web_arity_from_expr(expression: str, item_name: str) -> int:
    if "wrap_variadic" in expression:
        arg_indices = [
            int(index)
            for index in re.findall(r"arg_number\(\s*args\s*,\s*(\d+)\s*,", expression)
        ]
        if len(arg_indices) > 0:
            return max(arg_indices) + 1
        fail(
            "web host entries parse failure: tuple "
            f"'{item_name}' uses wrap_variadic but no arg_number(args, idx, ...) "
            "calls were found"
        )
    inline_match = re.search(r"@js\.from_fn(?P<arity>\d+)", expression)
    if inline_match is not None:
        return int(inline_match.group("arity"))
    fail(
        "web host entries parse failure: tuple "
        f"'{item_name}' has unsupported expression: {expression.strip()}"
    )


def parse_web_expr_arity(
    expression: str,
    let_expr_by_var: dict[str, str],
    inferred_arity_by_var: dict[str, int],
    item_name: str,
) -> int:
    identifier_match = re.fullmatch(r"[A-Za-z_]\w*", expression.strip())
    if identifier_match is None:
        return infer_web_arity_from_expr(expression, item_name)
    identifier = identifier_match.group(0)
    cached_arity = inferred_arity_by_var.get(identifier)
    if cached_arity is not None:
        return cached_arity
    let_expression = let_expr_by_var.get(identifier)
    if let_expression is None:
        fail(
            "web host entries parse failure: tuple "
            f"'{item_name}' references unknown identifier '{identifier}'"
        )
    inferred_arity = infer_web_arity_from_expr(let_expression, item_name)
    inferred_arity_by_var[identifier] = inferred_arity
    return inferred_arity


def parse_web_top_level_lets(source: str) -> dict[str, str]:
    table: dict[str, str] = {}
    for match in TOP_LEVEL_WEB_LET_RE.finditer(source):
        table[match.group("name")] = match.group("expr").strip()
    if len(table) == 0:
        fail("web host parse failure: no top-level `let` bindings found")
    return table


def extract_mgstudio_host_entries_block(source: str, file_path: Path) -> str:
    anchor = "let mgstudio_host = @js.from_entries(["
    anchor_index = source.find(anchor)
    if anchor_index < 0:
        fail(f"{file_path}: cannot find `{anchor}`")
    list_open_index = source.find("[", anchor_index)
    if list_open_index < 0:
        fail(f"{file_path}: cannot find '[' for mgstudio_host entries")
    list_close_index = find_balanced_close(source, list_open_index, "[", "]")
    return source[list_open_index + 1 : list_close_index]


def parse_web_host(repo_root: Path) -> SourceTable:
    file_path = repo_root / "mgstudio-runtime/web/host/api.mbt"
    if not file_path.is_file():
        fail(f"missing file: {file_path}")
    source = file_path.read_text(encoding="utf-8")

    let_expr_by_var = parse_web_top_level_lets(source)
    inferred_arity_by_var: dict[str, int] = {}
    list_body = extract_mgstudio_host_entries_block(source, file_path)

    table: dict[str, int] = {}
    for tuple_content in parse_tuple_content_items(list_body):
        key_match = re.match(r'\s*"(?P<name>[A-Za-z_]\w*)"\s*,', tuple_content, re.DOTALL)
        if key_match is None:
            fail(
                f"{file_path}: cannot parse tuple key from entry: {tuple_content.strip()}"
            )
        name = key_match.group("name")
        expression = tuple_content[key_match.end() :].strip()
        arity = parse_web_expr_arity(
            expression, let_expr_by_var, inferred_arity_by_var, name
        )
        append_func(table, name, arity, file_path.as_posix())
    return SourceTable("runtime/web", table)


def report_table_summary(
    expected: SourceTable, runtime: SourceTable, strict_extra: bool
) -> tuple[int, int]:
    expected_names = set(expected.funcs.keys())
    runtime_names = set(runtime.funcs.keys())

    missing_names = sorted(expected_names - runtime_names)
    extra_names = sorted(runtime_names - expected_names)
    mismatched_names = sorted(
        name
        for name in (expected_names & runtime_names)
        if expected.funcs[name] != runtime.funcs[name]
    )

    print(
        f"[host-abi-check] {runtime.source_name}: "
        f"expected={len(expected_names)} "
        f"implemented={len(runtime_names)} "
        f"missing={len(missing_names)} "
        f"arity_mismatch={len(mismatched_names)} "
        f"extra={len(extra_names)}"
    )

    for name in missing_names:
        print(
            f"  - missing: {name}(expected arity={expected.funcs[name]})",
            file=sys.stderr,
        )
    for name in mismatched_names:
        print(
            f"  - arity mismatch: {name}(expected={expected.funcs[name]}, actual={runtime.funcs[name]})",
            file=sys.stderr,
        )
    if strict_extra:
        for name in extra_names:
            print(
                f"  - extra: {name}(arity={runtime.funcs[name]})",
                file=sys.stderr,
            )

    hard_failures = len(missing_names) + len(mismatched_names)
    if strict_extra:
        hard_failures += len(extra_names)
    return hard_failures, len(extra_names)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Check mgstudio_host function names and parameter arity "
            "across engine imports and all runtimes."
        )
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Repository root path (default: script parent parent).",
    )
    parser.add_argument(
        "--strict-extra",
        action="store_true",
        help="Fail when runtime has extra mgstudio_host functions not used by engine.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.resolve()

    expected = parse_engine_expected(repo_root)
    runtimes = [
        parse_native_wasmoon(repo_root),
        parse_native_wasmtime(repo_root),
        parse_web_host(repo_root),
    ]

    print(
        f"[host-abi-check] {expected.source_name}: total imports={len(expected.funcs)}"
    )

    total_failures = 0
    total_extras = 0
    for runtime in runtimes:
        failures, extras = report_table_summary(expected, runtime, args.strict_extra)
        total_failures += failures
        total_extras += extras

    if total_failures > 0:
        failure_kind = (
            "missing/mismatched/extra"
            if args.strict_extra
            else "missing/mismatched"
        )
        print(
            f"[host-abi-check] failed: {total_failures} {failure_kind} functions.",
            file=sys.stderr,
        )
        return 1

    if total_extras > 0:
        print(
            "[host-abi-check] success with extras: "
            f"{total_extras} runtime-only functions (not used by engine)."
        )
    else:
        print("[host-abi-check] success: all runtimes match engine imports.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
