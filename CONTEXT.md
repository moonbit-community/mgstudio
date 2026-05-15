# Moon Game Studio

Moon Game Studio is a MoonBit game engine project whose domain language is centered on reproducing Bevy within the scope that MoonBit can realistically express.

## Language

**Bevy Replication**:
Reproducing the pinned Bevy baseline for all in-scope crates and examples across source topology, public API, runtime semantics, tests, visual behavior, and performance.
_Avoid_: complete Bevy clone, Bevy-inspired, Bevy-like

**Out-of-Scope Bevy Surface**:
Parts of Bevy that are intentionally excluded because MoonBit cannot realistically express or support them.
_Avoid_: missing parity, unfinished Bevy scope

**Runtime Parity Priority**:
The rule that in-scope Bevy replication is judged first by runtime behavior, visual output, and performance, while preserving source topology and public API as much as possible.
_Avoid_: source-only parity, topology-first parity

**Severe Performance Gap**:
An in-scope runtime path that is more than four times slower than the pinned Bevy baseline under comparable measurement conditions.
_Avoid_: minor slowdown, acceptable drift

**Evidence-Based Parity Cause**:
A parity gap explanation proven by direct mgstudio-versus-Bevy breakdown, source comparison, and measured evidence rather than conjecture.
_Avoid_: likely root cause, suspected cause, guess

**Human Visual Parity Judgment**:
The rule that visual parity is ultimately accepted or rejected by a human developer reviewing mgstudio artifacts against the pinned Bevy baseline.
_Avoid_: screenshot-only parity, automated visual truth

**Bevy Source Owner**:
The Bevy crate, module, or source path that owns a behavior or API in the pinned baseline and defines the minimum unit for parity analysis.
_Avoid_: mgstudio folder owner, current port location

**Implementation Fragment**:
One mgstudio package, file, or bridge layer that implements part of a single Bevy source owner because of MoonBit package, dependency, or language constraints.
_Avoid_: independent parity module, separate owner

**Runtime Owner Semantics**:
The rule that ownership of runtime behavior, lifecycle, resources, and scheduling should match the Bevy source owner even when MoonBit requires bridge packages or re-exports.
_Avoid_: file-location ownership, bridge-owned behavior

**External Blocker**:
A parity blocker caused by missing or insufficient capability in an upstream MoonBit dependency or ecosystem package rather than mgstudio's own implementation.
_Avoid_: mgstudio parity gap, local workaround target

**External Blocker Reproduction**:
The minimum evidence package that lets a community dependency maintainer implement and verify the missing Bevy-required capability.
_Avoid_: vague upstream note, dependency complaint

**Recorded External-Blocker Workaround**:
A temporary mgstudio-side unblock path for an external blocker that is explicitly recorded, does not count as completed parity, and has a dependency-resolution deletion condition.
_Avoid_: silent workaround, completed parity claim, permanent compatibility layer

**Blocked Parity Subtarget**:
A portion of a Bevy source owner whose parity work cannot continue until an external blocker is resolved.
_Avoid_: abandoned module, local fallback target

**Cause Unverified Performance Gap**:
A severe performance gap with measurements and candidate causes, but without enough evidence to promote any candidate to an evidence-based parity cause.
_Avoid_: diagnosed root cause, known cause, fixed later

**Trace-First Performance Diagnosis**:
The rule that cause-unverified performance gaps must be investigated with instrumentation, trace breakdowns, and Bevy comparison before code restructuring.
_Avoid_: refactor-first performance fix, speculative optimization

**Reusable Profiling Evidence**:
Performance evidence captured through reusable profiling or diagnostics infrastructure rather than one-off debug logs.
_Avoid_: temporary debug log evidence, ad hoc timing

**Disposable Bevy Measurement Patch**:
A temporary local modification to the pinned `./bevy` checkout used only to collect parity measurement evidence and never committed or copied into mgstudio semantics.
_Avoid_: Bevy fork, source port, semantic dependency

**Repeated Measurement Patch**:
A disposable Bevy measurement patch or script saved under `.private/` because the same performance gap needs repeated remeasurement.
_Avoid_: committed Bevy patch, permanent baseline fork

## Relationships

- **Bevy Replication** excludes every **Out-of-Scope Bevy Surface**.
- An **Out-of-Scope Bevy Surface** is not counted as a parity gap unless the project explicitly moves it into scope.
- **Runtime Parity Priority** constrains **Bevy Replication** for every in-scope Bevy surface.
- Every **Severe Performance Gap** requires an **Evidence-Based Parity Cause** before it is treated as understood.
- **Human Visual Parity Judgment** is the acceptance authority for visual aspects of **Bevy Replication**.
- A **Bevy Source Owner** defines the minimum work unit for module parity analysis, even when the mgstudio implementation is split across multiple packages.
- A **Bevy Source Owner** may map to many **Implementation Fragments**, but those fragments remain one parity unit unless Bevy itself defines separate owners.
- **Runtime Owner Semantics** takes priority over matching Bevy file placement when MoonBit package or dependency constraints require bridge packages.
- An **External Blocker** is tracked separately from mgstudio implementation parity and can become community dependency work.
- Every **External Blocker** requires an **External Blocker Reproduction** before it is actionable for the community.
- A **Recorded External-Blocker Workaround** may exist for an **External Blocker**, but it must not be counted as completed parity.
- A **Blocked Parity Subtarget** may still receive tests, documentation, reproduction work, or unrelated cleanup, but not local substitute behavior for the blocked dependency capability.
- A **Cause Unverified Performance Gap** remains unresolved until one candidate cause becomes an **Evidence-Based Parity Cause**.
- **Trace-First Performance Diagnosis** applies before refactoring any **Cause Unverified Performance Gap**.
- **Trace-First Performance Diagnosis** should produce **Reusable Profiling Evidence** whenever the measurement will support future parity work.
- A **Disposable Bevy Measurement Patch** may be used to collect Bevy-side evidence for **Trace-First Performance Diagnosis**.
- A **Disposable Bevy Measurement Patch** is documented by summary and artifact paths by default; it becomes a **Repeated Measurement Patch** only when repeated remeasurement is expected.

## Example dialogue

> **Dev:** "Does **Bevy Replication** require `bevy_reflect` parity?"
> **Domain expert:** "No — that is an **Out-of-Scope Bevy Surface** unless we explicitly move it into scope."
>
> **Dev:** "Should we preserve Bevy's file layout if the runtime behavior is still wrong?"
> **Domain expert:** "No — **Runtime Parity Priority** means behavior, visuals, and performance define success first, with source topology and API preserved where practical."
>
> **Dev:** "Can we call a 5x slower hot path acceptable because it still renders correctly?"
> **Domain expert:** "No — that is a **Severe Performance Gap**, and we need an **Evidence-Based Parity Cause** before deciding what to do."
>
> **Dev:** "Can the screenshot gate decide visual parity by itself?"
> **Domain expert:** "No — the gate provides artifacts, but **Human Visual Parity Judgment** decides whether the output matches Bevy."
>
> **Dev:** "Should we audit parity by the current mgstudio folder layout?"
> **Domain expert:** "No — use the **Bevy Source Owner** first, then map all mgstudio implementation pieces back to that owner."
>
> **Dev:** "If MoonBit forces a Bevy owner across three mgstudio packages, do we open three parity modules?"
> **Domain expert:** "No — those are **Implementation Fragments** of one **Bevy Source Owner**."
>
> **Dev:** "Should bridge packages own behavior just because code lives there?"
> **Domain expert:** "No — **Runtime Owner Semantics** stays with the **Bevy Source Owner**; bridges only keep the port buildable and traceable."
>
> **Dev:** "If `moon_taffy` lacks a Bevy-required layout capability, is that a mgstudio parity gap?"
> **Domain expert:** "No — that is an **External Blocker** and should be tracked so the community can build the missing dependency capability."
>
> **Dev:** "Can we just say the dependency is missing a feature?"
> **Domain expert:** "No — an **External Blocker** needs an **External Blocker Reproduction** with the dependency, Bevy requirement, blocked owner, and verification expectation."
>
> **Dev:** "Can mgstudio temporarily unblock an external blocker while waiting for the dependency?"
> **Domain expert:** "Yes, but only as a **Recorded External-Blocker Workaround** with a deletion condition, and it must not count as completed parity."
>
> **Dev:** "Can we keep working near a blocked owner?"
> **Domain expert:** "Yes, but only around the **Blocked Parity Subtarget**: add evidence, tests, docs, or unrelated cleanup without adding substitute behavior."
>
> **Dev:** "If a hot path is 15x slower and we have plausible explanations, is it diagnosed?"
> **Domain expert:** "No — it is a **Cause Unverified Performance Gap** until one explanation is proven by mgstudio-versus-Bevy evidence."
>
> **Dev:** "Can we refactor a cause-unverified performance gap because the candidate cause looks obvious?"
> **Domain expert:** "No — **Trace-First Performance Diagnosis** requires instrumentation and Bevy comparison first."
>
> **Dev:** "Can temporary debug logs be the official performance breakdown?"
> **Domain expert:** "No — official breakdowns should use **Reusable Profiling Evidence** whenever possible."
>
> **Dev:** "Can we patch local `./bevy` to add a counter for comparison?"
> **Domain expert:** "Yes, as a **Disposable Bevy Measurement Patch** that is documented, not committed, and not copied into mgstudio semantics."
>
> **Dev:** "Should we save every local Bevy measurement patch as a file?"
> **Domain expert:** "No — save only the summary and artifacts by default; use a **Repeated Measurement Patch** under `.private/` when the measurement will be reused."

## Flagged ambiguities

- "完全复刻 Bevy" could imply every Bevy crate and internal mechanism; resolved: **Bevy Replication** excludes surfaces that MoonBit cannot realistically express or support.
- "source topology/API parity" could imply layout-only success; resolved: **Runtime Parity Priority** makes runtime behavior, visual output, and performance the primary acceptance surface.
- "性能差距" could mean any slowdown; resolved: a slowdown greater than 4x is a **Severe Performance Gap**.
- "原因" could mean a hypothesis; resolved: parity causes must be **Evidence-Based Parity Cause** entries grounded in mgstudio-versus-Bevy breakdowns.
- "visual parity" could imply automated screenshot metrics are authoritative; resolved: **Human Visual Parity Judgment** is required for final visual acceptance.
- "module" could mean a MoonBit package folder; resolved: parity modules are defined by **Bevy Source Owner** boundaries first.
- "fragment" could imply an independent parity target; resolved: an **Implementation Fragment** is part of its **Bevy Source Owner** unless Bevy defines a separate owner.
- "owner" could mean the file where code currently lives; resolved: **Runtime Owner Semantics** follows the **Bevy Source Owner**, with bridges and re-exports used only for MoonBit constraints.
- "dependency limitation" could be counted as a local engine gap; resolved: missing upstream MoonBit package capability is an **External Blocker**.
- "external blocker" could be a vague note; resolved: it must include an **External Blocker Reproduction** to be actionable.
- "temporary compatibility layer" could look like completed parity; resolved: it must be a **Recorded External-Blocker Workaround** and remain tied to the external blocker.
- "blocked" could imply no work is allowed nearby; resolved: a **Blocked Parity Subtarget** only forbids substitute behavior for the missing dependency capability.
- "diagnosed performance gap" could mean plausible explanation; resolved: severe gaps with only candidate causes are **Cause Unverified Performance Gap** entries.
- "performance fix" could start with refactoring; resolved: **Trace-First Performance Diagnosis** comes before restructuring cause-unverified gaps.
- "instrumentation" could mean throwaway logs; resolved: parity-grade performance evidence should be **Reusable Profiling Evidence**.
- "Bevy patch" could imply a forked source of truth; resolved: local Bevy instrumentation is only a **Disposable Bevy Measurement Patch**.
- "measurement patch" could imply a tracked project artifact; resolved: it is summarized by default and saved under `.private/` only as a **Repeated Measurement Patch**.
