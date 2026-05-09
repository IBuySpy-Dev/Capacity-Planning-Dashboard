# Token Economics — Turn Budget Reference

## Task Classification

Classify each task before starting and state the classification at the top of your plan.

| Class | Definition | Soft turn budget |
|---|---|---|
| **Routine** | Matches a known pattern already covered by instructions or memory | ≤ 3 turns |
| **Familiar** | Partial match — similar to prior work but with new variables | ≤ 5 turns |
| **Novel** | No prior coverage; first time encountering this pattern | Estimate N turns upfront; state it |

Novel tasks pay a learning cost — do not treat overrun as failure.

## Failure Protocol — Stuck After 5 Turns

If a task has consumed > 5 turns **and** there has been no measurable forward progress:

Forward progress = at least one of:

- A new test passes that did not pass before
- A new error class is resolved
- A file reaches its intended target state
- A blocker is identified and removed

**When stuck:**

1. Log the failure pattern to memory: task, approach, failure mode, blocking signal
2. Try a different approach, escalate model tier, or break into smaller units
3. Do not escalate model tier as the first response — change approach first

## Success Protocol

When a task completes within budget and tests pass:

- If the solution involved a non-obvious pattern: call `store_memory`
- If it was a well-known pattern: skip — reinforcing boilerplate dilutes signal

## TRM Progress Estimator

```text
estimate(t) = estimate(t-1) × 0.7 + observation(t) × 0.3
```

Where `observation(t)` = fraction of task checklist items completed this turn.
Checkpoint fires when `estimate.progress / estimate.turns_remaining < 0.6`.

If TRM overhead would exceed 15% of remaining context budget, skip Pass 2 and accept Pass 1 result.

## Review Lens

- Is the model tier the lowest-cost that can do the work reliably?
- Was context loaded in priority order rather than dumped all at once?
- Were already-loaded files reused instead of re-read?
- Were targeted sections used instead of whole-file reads?
- If premium reasoning was used, was the cost-quality tradeoff stated?
- Was the task classified before starting?
- If stuck past 5 turns, was failure logged and approach changed?
- If completed within budget with test validation, was a novel pattern stored?
