---
name: No subagents for execution
description: User prefers direct execution over spawning subagents, even for full phase execution
type: feedback
---

Do not spawn subagents to execute plans — do the work directly yourself.

**Why:** User explicitly requested "do not use a subagent to execute this phase, do it yourself" during Phase 6 execution. Previous feedback was for quick fixes only — this extends to full phase execution too.

**How to apply:** For all execution work (phase plans, fixes, UAT), edit the code directly inline. Only use subagents for truly parallelizable research tasks where the user explicitly requests it.
