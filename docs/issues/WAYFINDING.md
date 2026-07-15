# Wayfinding operations

This repository represents Wayfinder maps and decision tickets in the existing
Markdown tracker under `docs/issues`.

- A map is an open epic whose labels include `wayfinder:map`.
- A decision ticket is a child of the map through its `Parent` relationship and
  carries exactly one `wayfinder:research`, `wayfinder:prototype`,
  `wayfinder:grilling`, or `wayfinder:task` label.
- Hard ordering is represented with `Depends on`; the derived reverse edge is
  `Blocks`.
- The frontier is the map's open, unassigned child tickets whose dependencies
  are all closed. Regenerate `README.md`, then filter its ready queue by the
  map's child relationship.
- Claim a ticket before working it by setting `Assignee` and changing `Status`
  to `in_progress`.
- Resolve a ticket by recording the answer in `Close Notes`, changing `Status`
  to `closed`, and adding a one-line named link under the map's
  `Decisions so far` section.
- Add newly visible decisions as child tickets in one pass, then add dependency
  edges in a second pass. Keep questions that cannot yet be stated precisely in
  the map's `Not yet specified` section.
- Regenerate `docs/issues/README.md` after every tracker mutation.

Use ticket titles, not bare `ISS` identifiers, in developer-facing narration.

