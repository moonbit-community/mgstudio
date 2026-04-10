#!/usr/bin/env node
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

import fs from "node:fs"
import path from "node:path"
import { excludeReasonForSource } from "./bevy_rs_to_mbt_excludes.mjs"

const REPO_ROOT = process.cwd()
const args = new Set(process.argv.slice(2))

function pickScope() {
  for (const arg of args) {
    if (arg.startsWith("--scope=")) return arg.slice("--scope=".length)
  }
  if (args.has("--all")) return "all"
  if (args.has("--examples")) return "examples"
  if (args.has("--extra")) return "extra"
  return "crates"
}

const scope = pickScope()
const syncMode = args.has("--sync")
const jsonMode = args.has("--json")
const strictExamples = args.has("--examples-strict")
const includeNonGoal = args.has("--include-non-goal")
const includeExcluded = args.has("--include-excluded")

const HEADER = `// Copyright 2025 International Digital Economy Academy
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
`

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    if (ent.name.startsWith(".")) continue
    if (ent.isDirectory() && ent.name === "_build") continue
    const p = path.join(dir, ent.name)
    if (ent.isDirectory()) walk(p, out)
    else out.push(p)
  }
  return out
}

function slash(p) {
  return p.replaceAll(path.sep, "/")
}

function rel(p) {
  return slash(path.relative(REPO_ROOT, p))
}

function rsToMbtSubpath(sub) {
  if (sub === "mod.rs") return "top.mbt"
  if (sub.endsWith("/mod.rs")) return `${sub.slice(0, -"/mod.rs".length)}/top.mbt`
  return `${sub.slice(0, -".rs".length)}.mbt`
}

function buildExampleRecord(exampleSub, source) {
  const mbtSub = rsToMbtSubpath(exampleSub)
  const topTarget = `mgstudio-engine/examples/${mbtSub}`
  const mainTarget = `mgstudio-engine/examples/${exampleSub.slice(0, -".rs".length)}/main.mbt`
  const excludeReason = excludeReasonForSource(source, {
    includeNonGoal,
    includeExcluded,
    exampleSub,
  })
  const candidates =
    strictExamples || exampleSub === "mod.rs" || exampleSub.endsWith("/mod.rs")
      ? [topTarget]
      : [mainTarget, topTarget]
  return {
    source,
    target: candidates[0],
    candidates,
    excluded: excludeReason !== null,
    exclude_reason: excludeReason,
  }
}

function bevyCrateRecords() {
  const cratesRoot = path.join(REPO_ROOT, "bevy", "crates")
  const crateNames = fs
    .readdirSync(cratesRoot, { withFileTypes: true })
    .filter((d) => d.isDirectory() && d.name.startsWith("bevy_"))
    .map((d) => d.name.slice("bevy_".length))
    .sort()

  const records = []
  for (const crate of crateNames) {
    const srcRoot = path.join(cratesRoot, `bevy_${crate}`, "src")
    if (!fs.existsSync(srcRoot)) continue
    const rsFiles = walk(srcRoot).filter((p) => p.endsWith(".rs"))
    for (const rs of rsFiles) {
      const rsSub = rel(rs).slice(`bevy/crates/bevy_${crate}/src/`.length)
      const mbtSub = rsToMbtSubpath(rsSub)
      const source = rel(rs)
      const excludeReason = excludeReasonForSource(source, { includeNonGoal, includeExcluded })
      records.push({
        source,
        target: `mgstudio-engine/${crate}/${mbtSub}`,
        candidates: [`mgstudio-engine/${crate}/${mbtSub}`],
        excluded: excludeReason !== null,
        exclude_reason: excludeReason,
      })
    }
  }
  return records
}

function bevyExampleRecords() {
  const srcRoot = path.join(REPO_ROOT, "bevy", "examples")
  const rsFiles = walk(srcRoot).filter((p) => p.endsWith(".rs"))
  return rsFiles.map((rs) => {
    const source = rel(rs)
    const rsSub = source.slice("bevy/examples/".length)
    return buildExampleRecord(rsSub, source)
  })
}

function bevyExtraRecords() {
  return []
}

function bevyFullRecords() {
  return [...bevyCrateRecords(), ...bevyExampleRecords()]
}

function ensureFile(target, source) {
  const abs = path.join(REPO_ROOT, target)
  if (fs.existsSync(abs)) return false
  fs.mkdirSync(path.dirname(abs), { recursive: true })
  const anchor = `\n// Bevy source-shape anchor: ${source}\n`
  fs.writeFileSync(abs, `${HEADER}${anchor}`)
  return true
}

function scaffoldMetrics() {
  const root = path.join(REPO_ROOT, "mgstudio-engine")
  const files = walk(root).filter((p) => p.endsWith(".mbt"))
  let scaffold_files = 0
  let scaffold_with_bevy_source = 0
  for (const file of files) {
    const text = fs.readFileSync(file, "utf8")
    if (!text.includes("_scaffold_owner()")) continue
    scaffold_files += 1
    if (text.includes("Bevy source: `bevy/")) {
      scaffold_with_bevy_source += 1
    }
  }
  return {
    scaffold_files,
    scaffold_with_bevy_source,
    scaffold_without_bevy_source: scaffold_files - scaffold_with_bevy_source,
  }
}

const records =
  scope === "examples"
    ? bevyExampleRecords()
    : scope === "extra"
      ? bevyExtraRecords()
      : scope === "all"
        ? bevyFullRecords()
        : bevyCrateRecords()
const effective = records.filter((r) => !r.excluded)
const excludedByReason = new Map()
for (const record of records) {
  if (!record.excluded || record.exclude_reason === null) continue
  const prev = excludedByReason.get(record.exclude_reason) ?? 0
  excludedByReason.set(record.exclude_reason, prev + 1)
}
const targetToSources = new Map()
for (const record of effective) {
  const sources = targetToSources.get(record.target) ?? []
  sources.push(record.source)
  targetToSources.set(record.target, sources)
}
const collisions = Array.from(targetToSources.entries())
  .filter(([, sources]) => sources.length > 1)
  .map(([target, sources]) => ({ target, sources }))

const modRuleViolations = effective
  .filter((r) => r.source.endsWith("/mod.rs") || r.source.endsWith("mod.rs"))
  .filter((r) => !(r.target.endsWith("/top.mbt") || r.target.endsWith("top.mbt")))
  .map((r) => ({ source: r.source, target: r.target }))

const missing = effective.filter(
  (r) => !r.candidates.some((target) => fs.existsSync(path.join(REPO_ROOT, target))),
)

let created = 0
if (syncMode) {
  for (const m of missing) {
    if (ensureFile(m.target, m.source)) created += 1
  }
}
const scaffolds = scaffoldMetrics()

const payload = {
  scope,
  total_rs: records.length,
  considered_rs: effective.length,
  excluded_rs: records.length - effective.length,
  strict_examples: strictExamples,
  include_non_goal: includeNonGoal,
  include_excluded: includeExcluded,
  excluded_by_reason: Object.fromEntries(
    Array.from(excludedByReason.entries()).sort((a, b) => a[0].localeCompare(b[0])),
  ),
  collision_count: collisions.length,
  mod_rule_violation_count: modRuleViolations.length,
  missing: missing.length,
  created,
  scaffold_files: scaffolds.scaffold_files,
  scaffold_with_bevy_source: scaffolds.scaffold_with_bevy_source,
  scaffold_without_bevy_source: scaffolds.scaffold_without_bevy_source,
  sample_collisions: collisions.slice(0, 20),
  sample_mod_rule_violations: modRuleViolations.slice(0, 20),
  sample_missing_targets: missing.slice(0, 80).map((m) => m.target),
}

if (jsonMode) {
  console.log(JSON.stringify(payload, null, 2))
} else {
  console.log(
    `scope=${payload.scope} total_rs=${payload.total_rs} missing=${payload.missing} created=${payload.created}`,
  )
  console.log(
    `scaffolds=${payload.scaffold_files} with_source=${payload.scaffold_with_bevy_source} without_source=${payload.scaffold_without_bevy_source}`,
  )
  if (missing.length > 0) {
    for (const entry of payload.sample_missing_targets) console.log(entry)
    if (missing.length > payload.sample_missing_targets.length) {
      console.log(`... (${missing.length - payload.sample_missing_targets.length} more)`)
    }
  }
}

if (missing.length > 0 && !syncMode) process.exitCode = 2
if (collisions.length > 0) process.exitCode = 3
if (modRuleViolations.length > 0) process.exitCode = 4
