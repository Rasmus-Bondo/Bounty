# Roblox MCP Lazy Tool Loading

## Problem

The Roblox Studio MCP server exposes ~45 tools, each with full JSON schemas, parameter descriptions, enums, and examples. These are all loaded into the LLM's context window on every turn, consuming an estimated 30-40% of the 200K token budget — even when most tools go unused in a given conversation.

## Proposed Solution: `get_info` Parameter

Add a `get_info: boolean` parameter to each tool and make all other parameters optional in the schema. Descriptions and examples are stripped from the schema — they're returned at runtime when the model calls with `get_info: true`.

### Flow

1. Model sees 45 tools with short descriptions, parameter names (no descriptions), and a `get_info` boolean
2. Model decides it needs `set_property`
3. Model calls `set_property(get_info: true)` → gets full parameter docs, valid values, examples back into conversation context
4. Model calls `set_property(instancePath: "...", propertyName: "...", propertyValue: ...)` with correct params learned from step 3
5. On subsequent uses of `set_property` in the same conversation, the model already has the docs — no repeat lookup needed

### Schema Design

Each tool keeps its original parameter names (cheap, helps on repeat calls) but strips all descriptions, enums, and examples:

```json
{
  "name": "set_property",
  "description": "Set a property on an instance.",
  "parameters": {
    "type": "object",
    "properties": {
      "get_info": { "type": "boolean" },
      "instancePath": { "type": "string" },
      "propertyName": { "type": "string" },
      "propertyValue": {}
    }
  }
}
```

No required fields. The server validates at runtime and returns helpful errors pointing to `get_info: true` if required params are missing.

### What `get_info: true` Returns

The full documentation that was previously in the schema:
- Parameter descriptions and types
- Valid enum values
- Format requirements (e.g., "instancePath uses dot notation like `game.Workspace.Part`")
- Usage examples
- Related tools and when to prefer them

## Why This Works

- LLMs don't need param descriptions in the tool schema to format calls correctly — they follow instructions from conversation context just fine
- Parameter names are still visible in the schema, so on repeat calls the model doesn't need to look up docs again
- Tool names themselves serve as the catalog — no separate discovery mechanism needed
- The info lookup is a one-time cost per tool per conversation; context bloat is a per-turn cost forever

## Advantages Over Two-Tool Split (Previous Approach)

An earlier version of this design split each tool into `<tool>` and `<tool>_info` — two separate tools. The `get_info` parameter approach is better because:

- **45 tools instead of 90** — less noise in the tool list
- **No naming convention to maintain** — no `_info` suffix everywhere
- **Single entry point per capability** — the model doesn't have to decide between two tools
- **Simpler to implement** — one handler with a branch, not two registered tools

## Tradeoffs

| Benefit | Cost |
|---------|------|
| ~70-80% reduction in tool definition context | One extra round-trip per first use of each tool |
| Same tool count (45) | All params optional in schema — runtime validation needed |
| Only loads docs for tools actually used | Risk of model skipping info step and guessing params |
| Scales better as tool count grows | Similar tools need good enough one-liners to disambiguate |

## Design Considerations

### The model might skip `get_info` and guess

With parameter names visible in the schema, the model might try to call directly without getting docs first. This has three outcomes:

1. **Guesses correctly** — great, saved a round-trip. This is likely for tools with obvious params like `delete_object(instancePath: "...")`
2. **Guesses wrong on types/format** — server returns a validation error with a message like "instancePath must use dot notation (e.g., `game.Workspace.Part`). Call with `get_info: true` for full parameter docs." Self-correcting.
3. **Misses required params** — server returns "missing required field X. Call with `get_info: true` for full parameter docs." Self-correcting.

Outcome 1 is a win. Outcomes 2 and 3 cost one wasted call but the error message guides the model to the right path. This is arguably better than the two-tool approach where the model could also skip the info tool.

### Fully opaque alternative

If skipping `get_info` becomes a real problem, params can be hidden entirely:

```json
{
  "name": "set_property",
  "description": "Set a property on an instance.",
  "parameters": {
    "type": "object",
    "properties": {
      "get_info": { "type": "boolean" },
      "args": { "type": "object" }
    }
  }
}
```

This forces the model to call `get_info: true` because it can't see what keys to put in `args`. But it loses type safety and makes repeat calls harder since the model has to recall param names from conversation context. Not recommended unless skipping becomes a measured problem.

### Disambiguation for similar tools

Some tools are hard to distinguish from a short description (e.g., `set_property` vs `set_relative_property` vs `set_calculated_property` vs `mass_set_property`). Options:

1. **Descriptive one-liners** — Focus on the *when* not the *what*: "Set a property to an absolute value" vs "Modify a property relative to its current value" vs "Set a property via formula across multiple instances"
2. **Cross-references in get_info** — Each tool's info response mentions related tools and when to prefer them
3. **Accept occasional wrong picks** — Model calls wrong tool's `get_info`, realizes, tries another. Cost is one wasted round-trip, still cheaper than permanent context bloat

## Optimization: Preload High-Usage Tools

Monitor tool call frequency over time and preload full documentation for the top N most-used tools directly in the schema. These tools skip the `get_info` step entirely — full descriptions, enums, and examples baked in. The remaining tools stay lazy.

This eliminates the warm-up cost for common workflows while keeping the long tail lightweight.

### Per-user adaptive preloading

Usage patterns vary by workflow. A map builder hits `create_object` and `set_property` constantly. A scripter lives in `get_script_source` and `execute_luau`. Instead of a single global top-N, the server can maintain per-user call counts and preload the tools each user actually reaches for.

### Implementation

- Server logs tool call counts (per-user or global as a starting point)
- Each tool has a `preload` flag: `true` = include full docs in schema, `false` = strip docs
- Periodically recalculate the top N and update flags
- Everything else stays the same — lazy tools still have `get_info`, preloaded tools just don't need it

### Tuning N

The value of N is a context budget decision. Measure the token cost per preloaded tool and set N based on how much context budget you're willing to spend. Too few and you get warm-up latency on common tools; too many and you're back to the original bloat problem.

## Measuring Impact

### Before (current)
- Count total tokens used by tool definitions in the system prompt
- Method: Capture the full tool definition payload sent to the API, run it through a tokenizer
- Record: total token count, percentage of 200K context

### After (lazy loading)
- Count total tokens used by the stripped definitions (names + types, no descriptions)
- Count tokens added per `get_info` call (track across a sample conversation)
- Record: stub token count, average info tokens loaded per conversation, peak info tokens loaded

### Comparison metrics
- **Static overhead**: stripped definitions vs full definitions (tokens)
- **Typical session cost**: stripped defs + info lookups for a realistic 5-10 tool conversation vs full definitions
- **Break-even point**: how many unique tools per conversation before lazy loading costs more
- **Usable context freed**: difference in available tokens for actual conversation

### Test scenarios
1. Simple task — uses 2-3 tools (e.g., read a script, edit it, playtest)
2. Medium task — uses 8-10 tools (e.g., build a UI, set properties, create objects)
3. Heavy task — uses 20+ tools (e.g., full scene construction)

For each scenario, compare total context consumed across a full conversation.
