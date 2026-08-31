# 3 — Being killed by High Noon played no sound at all on the victim

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#3 — Being killed by High Noon played no sound at all on the victim.** *(Fixed 2026-08-04,
**VERIFIED by the owner the same day**. In Studio, **not yet published** — it ships in the next
release alongside #4.)*

**#3 and #4 do NOT share a root cause.** The standing note on this item predicted they would, and
the two were diagnosed together on that basis, but they turned out to be unrelated bugs in
different scripts on different sides of the wire. Neither was an ungrouped or unloaded Sound.
**Do not re-derive the shared-cause theory** if anything nearby is reopened.

**The cause was a missing call, and the bot had it all along.** `HunterHitPipeline` plays the
victim's impact through `BulletHitAudioService.Play`, gated on `opts.PlayBulletHitSound` — passed
by all four basic weapons (`RevolverModule`, `SunspikeModule`, `StarfallSightModule`,
`GrudgekeeperModule`). High Noon never reaches the pipeline: `HighNoonDamage` runs its own parallel
post-hit chain (its own damage-direction, health-bar reveal, kill feed, kill cam, flash) and simply
never made the audio call. The **bot** path, `BotCombat:_applyUltimateHit`, *did* — so a Dust bot's
High Noon had always played the victim's hit sound and a player's never had. This is the usual
"is there a bot version?" check landing the other way round: the bot was the correct implementation.

*Fixed by:* `BulletHitAudioService.Play(targetData.character, isHeadshot)` in
`HighNoonDamage:Apply`, unconditional — matching the pipeline rather than BotCombat's player-only
guard, so a bot body cracks the same way it does under the basic revolver. `SendDamageDirection`
also grew the `isHeadshot` and `isBulletImpact` arguments the shared version already passes;
`BulletImpactAudioClient` uses the second to suppress a near-miss whiz from the same shot, which
High Noon previously could not do.

**Required rather than injected, on purpose — do not "tidy" it into the constructor config.**
Everything else `HighNoonDamage` needs arrives through injection, and the module's own comment says
it stays dependency-free that way. The audio service is a hard `require` instead, because an
optional dependency can go missing without erroring, which is precisely how this bug worked.
`BulletHitAudioService` requires nothing itself, so there is no cycle to avoid. #10's `KillFeedGate`
wiring landed in the same module on the same day and took the same decision for the same reason.

**Not done: migrating High Noon onto `HunterHitPipeline.Register`,** which is what
`HunterImplementationGuide:320-324` tells you to do and which would delete the parallel chain
outright. It re-routes kill feed, kill cam, charge award and stats on a live ultimate — far too
large a regression surface for a P2 audio fix. The guide's warning is about *stats* specifically,
and that half was already closed on 2026-06-28. Worth doing on its own terms, not smuggled into an
audio fix. **This is the second item in four days to hand-add something to that parallel chain**
(#10 was the first); a third is the signal to stop patching and do the migration.

**Regression checklist if this area is touched again:** die to a player Dust's High Noon and
confirm the impact is audible; check a locked execute and an unlocked body shot both sound (the
execute takes the `HeadShotHit` sample, since High Noon's `isHeadshot` means "fully locked"); check
a six-target execute does not stack into a wall of noise — hits are staggered 0.12s by `ShotDelay`
and each victim's sound is positional on their own body.
