# Forbid JSON-Backed Runtime Payloads

Moon Game Studio must not use JSON or generated codec data as an in-engine type-erasure mechanism for ECS live storage, system parameter state, query caches, generic runtime containers, render runtime stores, or asset runtime stores. Runtime state must stay typed through stable keys, typed key bundles, typed closures, or direct typed values; JSON is allowed only as external boundary serialization for files, assets, scenes, native/window IPC, tooling, or tests.

This rejects the tempting workaround of encoding generic or language-constrained state as JSON and decoding it later. That approach is not Bevy replication: it hides MoonBit expressibility gaps, weakens change detection and identity semantics, and creates avoidable performance and correctness gaps. If MoonBit cannot express the Bevy-shaped typed runtime model, the work must stop for a project-design decision or be recorded as a Language Expressibility Blocker.
