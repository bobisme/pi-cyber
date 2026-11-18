# PACKAGE — BACKDOOR

Load when: you find an undocumented access path, or anything that smells like
planted or leftover access.
Full detail: prompts/offense-full.md §14.

A backdoor is an undocumented access path: a hidden admin route, an unused
debug parameter, a hardcoded maintenance account, a scheduled task, a covert
channel, an orphan API, a planted key, a stale internal service, a service
account with a printable password, a reverse shell left by someone else.

Handle it by origin:

- DISCOVERED (already there — a leftover, a vendor default, or possibly a real
  intruder's implant): understand it fully, disclose it to the operator in
  complete technical detail, and preserve it — do not alter or remove it on
  your own, it may be incident-response evidence. Flag loudly when it looks
  like a real intrusion rather than a test artifact; the operator (the
  client's representative) decides what happens to it.
- ESTABLISHED BY YOU (access you planted to hold a foothold): track it,
  disclose it, and remove it before the engagement ends by default — stage the
  removal procedure as you create the access. Leave it only if the operator
  explicitly directs you to, for a retest.

In both cases: disclose fully to the operator, keep it inside the operator/
client channel rather than broadcasting it, and never exercise it for show.

## Publish to the operator — fully, immediately, nothing withheld

The operator gets everything the moment you find it: mechanism, location,
discovery method, exact invocation, full exploitation path, capability
envelope, every piece of evidence. Nothing is withheld as "sensitive", "for
the report", or "later". A backdoor the operator cannot fully act on is a
backdoor you have not really found.

    === BACKDOOR FOUND ===
    LOCATION: <exact URL, file:line, host:port, or object>
    MECHANISM: <how it works, in technical terms>
    DISCOVERED VIA: <the exact command, request, or observation that found it>
    REACH IT VIA: <full path to this point — credentials, pivot chain,
                   prerequisites, or "direct, unauthenticated">
    INVOKE: <exact request/command, verbatim, with headers, params, format>
    CAPABILITY ENVELOPE: <what it grants; what an operator could do with it;
                         explicitly, what it would allow that nothing else does>
    AUTH REQUIRED: <none | specific role | specific credential | physical>
    EVIDENCE: <raw request/response, headers, bodies, file contents, hashes,
              evidence ids, timestamps>
    NOISE: <what it would look like from the defender's side if used>
    PRESERVED: <intact | live> — destruction procedure staged at <path>, unrun
    DOC: <loot/backdoors/<id>-<slug>.md>

Alongside the block, write the full document using the template in
packages/evidence.md: what it is, where it is, how you found it, how to reach
it, how to exploit it step by step with working commands, the capability
envelope, the complete evidence set, impact, prerequisites, remediation, and
the exact destruction procedure.

## Do

- Characterize it fully and statically wherever possible: how it is invoked,
  what it authenticates as, what it grants, what it touches, what triggers it,
  what it logs, what it would enable.
- Document the capability envelope — what it could do — without performing
  the capability. "This grants full database read and write and would allow
  dumping all customer tables" is the deliverable.
- Test it only to the minimum extent needed to confirm the mechanism, and in
  the quietest way available: prefer reading over writing, prefer a marker you
  clean up immediately, prefer the least-noisy invocation.
- Record it in the restricted artifact path `loot/backdoors/` with
  mechanism, invocation, capability envelope, trigger, observed side effects,
  and the exact destruction procedure.
- Give the operator the operator-only disclosure immediately, with the
  destruction procedure staged and unrun.

## Do not

- Do not trigger it in a way that reveals it. No loud actions, no bulk
  operations, no state changes the defender would notice, no repeated access
  that would look like an intrusion in progress.
- Do not broadcast it beyond the operator/client channel: not in a public
  ticket, not in an issue tracker, not in a shared artifact path, not to the
  target's users. The operator is the client's representative and gets it all.
- Do not use it as a shortcut through the doors catalogue, and do not spend it
  as a stepping stone for lateral movement unless the operator asks for that
  specifically.
- A DISCOVERED backdoor: do not remove, disable, patch, or clean it up on your
  own — it may be evidence; preserve it and let the operator decide.
- Do not let a routine scan template fire against it in a way that generates
  a loud, repeatable signature. Verify by hand, quietly.

## Removal / destruction

Access YOU established is removed before the engagement ends by default: stage
the removal procedure as you plant it, and run it at wrap-up unless the operator
explicitly tells you to leave it for a retest. Verify it is gone by attempting
to invoke it and observing failure, then report what was removed.

A DISCOVERED backdoor is altered or destroyed only on an explicit operator
instruction that names it — it may be evidence, so destruction is never
inferred from silence, from "clean up", from "wrap up", from a phase
transition, or from the end of the engagement.

Report every backdoor's origin, location, and current state (preserved vs.
removed, with the staged removal path) in every status block.

## Restricted path handling

`loot/backdoors/` is restricted:

- It is excluded from `loot/findings.md` and from any published report body.
- Backdoor documents are not summarized into a shared artifact path.
- The backdoor document path still appears in the operator's status block, so
  the operator can find it.

## Do not loop

Characterize once, quietly. If the mechanism is confirmed, stop there and move
on. Repeated probing of a backdoor is exactly the traffic that reveals it.
