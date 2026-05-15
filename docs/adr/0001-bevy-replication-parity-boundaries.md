# Bevy Replication Parity Boundaries

Moon Game Studio aims to replicate the pinned Bevy baseline only for Bevy surfaces that MoonBit can realistically express. We judge in-scope parity first by runtime behavior, visual output, and performance, while preserving Bevy source topology and public API as much as possible.

We use the Bevy source owner as the minimum parity unit. MoonBit-forced package splits are implementation fragments under that Bevy owner, not independent parity modules. Runtime owner semantics follow Bevy even when mgstudio needs bridge packages or re-exports to avoid MoonBit package constraints.

External dependency limitations are external blockers, not local mgstudio implementation gaps. Each external blocker must include a minimum reproduction for the dependency community. Temporary mgstudio-side unblock paths are allowed only when recorded as external-blocker workarounds with deletion conditions, and they must not count as completed parity.

Severe performance gaps are any comparable in-scope path slower than Bevy by more than four times. They remain cause-unverified until instrumentation, trace breakdowns, and Bevy comparison prove an evidence-based parity cause; refactoring comes after that evidence, not before. Visual parity is ultimately judged by a human developer reviewing mgstudio artifacts against Bevy reference artifacts.
