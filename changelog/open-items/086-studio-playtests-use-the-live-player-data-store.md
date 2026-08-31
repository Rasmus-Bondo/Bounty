# 86 — Studio playtests use the LIVE player data store

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**Studio playtests use the LIVE player data store.** `GetProfileStore("PlayerData_" ..
DATA_VERSION, ...)` has no `IsStudio()` branch and no Mock in either place, so pressing Play in
Studio takes a real session lock on a real profile — the cause of the "session locked too often"
symptom that `ForceLoadMaxSteps = 4` was papering over. `MatchDirectoryService` already solves
this one layer down by suffixing its MemoryStore map name under `IsStudio()`; the same treatment
belongs here. **Weigh first:** scoping Studio to its own store means playtests get an empty
profile — no owned hunters, no currency, no pass progress — so a seeded test profile is probably
wanted alongside it. *(raised: Launch)*
