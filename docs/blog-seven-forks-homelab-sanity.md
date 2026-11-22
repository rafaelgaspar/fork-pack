# Seven open-source forks for one homelab (and how I stopped dreading upstream releases)

I run a homelab that leans on other people’s software—a lot of it. Not “vendor appliance” a lot; “I need a small patch, a fresher runtime, and an image I can actually deploy” a lot. Over time that turned into **seven public application forks**: [homepage](https://github.com/rafaelgaspar/homepage), [supergateway](https://github.com/supercorp-ai/supergateway), [xpra](https://github.com/rafaelgaspar/xpra), [xpra-html5](https://github.com/rafaelgaspar/xpra-html5), [otbr-insight](https://github.com/rafaelgaspar/otbr-insight), [http-add-on](https://github.com/kedacore/http-add-on) (KEDA HTTP interceptor), and [moontide](https://github.com/rafaelgaspar/moontide) ([konni-arcadia/moontide](https://github.com/konni-arcadia/moontide)). Each one solves a real problem at home: dashboards, MCP gateways, remote GUI, Thread border routing insight, scale-to-zero HTTP routing, and live Strudel music via Moontide’s MCP stack.

Maintaining seven forks sounds like a part-time job. For a while, it *was*. The thing that saved my sanity wasn’t “try harder at git”—it was **one shared GitOps pack**, **predictable branch geometry**, **boring automation**, and **AI that knows the playbook** instead of improvising seven different workflows.

This is how that looks in practice.

## Why fork at all?

Upstream projects move at their own pace. My cluster moves at mine. I want:

- Container images on **GHCR** I control (homepage, supergateway, otbr-insight, http-add-on, moontide).
- **Full Debian packages** for Xpra server and client HTML5, not a hand-rolled overlay DEB that drifts from upstream.
- Small product tweaks (metrics, auth wrappers, Node/Go base images) without forking the entire release process every time.
- A path to **send fixes upstream** on `feat-upstream/*` branches without mixing deploy secrets into public repos.

A long-lived fork is a commitment. Seven of them is a commitment with compound interest—unless you treat the *system* as the product, not each repo in isolation.

## The failure mode I was heading toward

Without structure, each fork becomes its own snowflake:

- Rebase seven stacks by hand when upstream tags `v2.6.0`.
- Resolve the same wrapper conflict seven different ways.
- Copy-paste GitHub Actions YAML until one fork’s `github.sha` semantics bites you (rebuild 4.2.1, publish `v4.2.0-rafaelgaspar.1`—yes, that happened).
- Let Cursor “help” without guardrails and watch it commit to `main`, squash-merge on `rafaelgaspar`, or duplicate scripts across repos.

The breaking point is not the first conflict. It’s the **nightly question**: “Did upstream move? Are we current? If I touch this, will I break shipping?”

## One integration branch, one linear stack

Every fork uses the same branch story:

| Branch | Role |
| --- | --- |
| `main` / `master` | Upstream mirror only—auto-sync, no features |
| `feat/<name>` | Exactly **one commit** per layer, stacked on the parent |
| `rafaelgaspar` | Points at the stack tip—**only this branch ships** |

The stack is always linear:

```text
<upstream-tag>
 └── feat/rafaelgaspar          ← fork-pack overlay (scripts, tag-bump caller, skill)
      └── feat/latest-*-and-forky
           └── feat/<product-change>
                └── … → rafaelgaspar
```

**`feat/rafaelgaspar` is always the root** on the upstream release (or branch tip). Upstream’s CI workflows get **deleted** on the fork, not edited—so tag bumps don’t fight you on workflow YAML. Build and release machinery lives only on that root layer; child `feat/*` commits are product changes.

Stack order isn’t a JSON file—it’s **git history**: merge-base depth from the upstream tag. That keeps one source of truth and makes rebuild tooling straightforward.

Shipping is deliberately dumb: reset `rafaelgaspar` to the tip and push. The per-fork publish workflow runs on that pointer. No squash merges on the integration branch, no patch tarballs as artifacts—the image or release **is** the artifact.

## `fork-pack`: write automation once

[`rafaelgaspar/fork-pack`](https://github.com/rafaelgaspar/fork-pack) is the shared brain:

- `rebuild-rafaelgaspar.sh`—rebase the whole stack onto a new upstream tag or branch tip, optionally squash each layer, force-push with lease.
- A **reusable** tag-bump workflow (`workflow_call` only) that forks invoke with a thin caller YAML.
- `members.yaml`—which upstream URL, which tag glob/filter, tag vs branch tracking, which publish workflow.
- Cursor skills vendored onto forks via `install.sh` (skills live under `dot-cursor/` in the pack so they don’t activate *in* the pack repo itself).

Each fork keeps only what’s special: GHCR publish vs full `.deb` set vs HTML5 tarball, Debian build scripts for Xpra, and the thin scheduled caller. Everything about **how** to rebuild is centralized. When I fix a bug in tag resolution or publish checkout refs, I fix it once.

### Tag vs branch tracking

Not every upstream cuts semver tags on my schedule. In `members.yaml`:

- **`tracks: tag`** (default)—daily bump onto the latest release tag matching e.g. `^v[0-9]+\.[0-9]+\.[0-9]+$`.
- **`tracks: branch`**—track `master` or `main`; integration releases look like `v{tree-version}-{shortsha}-rafaelgaspar.N`.

Xpra server, xpra-html5, and http-add-on use branch tracking so I’m not waiting for a tag to pick up merged fixes. Homepage-style projects (including **moontide**) stay on release tags. Same script, different policy—configured in data, not copy-paste.

### Scheduled bumps that know when to shut up

Cron runs tag-bump (staggered per fork). If the upstream base commit is **already an ancestor of `rafaelgaspar`**, the job skips—no noise, no pointless force-pushes. Manual dispatch with an explicit tag always rebuilds (and ignores `tracks` for that run).

When a rebuild actually runs, it only pushes after the **entire stack** succeeds locally. Mergiraf is registered as a merge driver for the painful bits. Success or failure posts to Discord `#forks-tag-bump` so I’m not polling Actions at 4:15 AM.

## Conflicts: fewer than you fear, weirder than you expect

Most layers cherry-pick cleanly. What’s left is often embarrassingly specific: both sides wrapped the same HTTP export—`withAuth(handler)` vs `withApiMetrics(path, handler)`. Mergiraf usually keeps the handler body and leaves you to **union the wrappers**: `withAuth(withApiMetrics(path, handler))`. Taking “ours” or “theirs” for the whole file is how you **lose** overlay code you already merged (homepage’s `recordKubernetesStatsRequest` literally vanished that way on v2.6.0).

The playbook: keep glue thin (import + wrap), put behavior in fork-owned modules, add tests when you inject into upstream handlers.

When automation can’t finish, the job is not “open laptop at 4 AM and git status until coffee number three.” That’s what **Fixer** is for.

## Fixer: the fork specialist in Discord

**Fixer** is a Discord agent in my homelab—one member of a wider **Discord Agents** fleet (channels as inboxes, `@mentions` as work orders, skills as the contract). I’ll unpack how that fleet is wired, how agents share context, and when a human still has to click approve in a future post on **Discord Agents**. For this story, Fixer is the character that shows up when fork automation hits a wall.

Nightly tag-bump posts to `#forks-tag-bump` only when a rebuild was **attempted**—success or failure, not when cron correctly skips because we’re already current. A green message is closure: stack rebuilt, `rafaelgaspar` pushed, publish should follow. A red one is a bounded incident: repo, upstream tag, link to the Actions run, and often a line scraped from the rebuild log (`unresolved conflicts: …`). The footer is deliberate ops copy:

> Ask **@Fixer** to restack with the **fix-forks-conflicts** skill. Do not push `main`. Do not merge PRs.

So the webhook doesn’t just nag—it **routes**. Fixer is @mentioned with a named skill, not “please fix git.”

What Fixer actually does mirrors what I’d do by hand, but in a **per-fork agent worktree** on the cluster (`prepare-agent-worktree fixer`) so it’s not fighting my laptop checkout or another agent’s clone. It restacks the linear `feat/*` stack: mergiraf where it helps, union wrapper conflicts per the fork skill, `cherry-pick -n` per layer and **`sign_commit`** (signed stack), then operator-cued `--force-with-lease` on `feat/*` and `rafaelgaspar` only. Fixer does **not** run `rebuild-rafaelgaspar.sh` end-to-end in that pod—the script’s normal path calls `git commit`, which is blocked on those agent pods by design. Restack is the surgical path after a failed CI rebuild.

That split is why Fixer deserves a name in this post: **cron + fork-pack** handles the happy path; **Discord + Fixer** handles the long tail without me becoming the merge driver for seven repos.

## Where AI actually helps (vs where it hurts)

AI didn’t replace git. It replaced **re-explaining the same invariants every session**.

### “Read the skill first”—every fork session

Whether I’m in Cursor or talking to **Fixer** on Discord, I don’t start with the task. I start with the playbook:

> Please read the skill on how to work with the fork first before any work is done.

The vendored skill is **`rafaelgaspar-fork`**; fork-pack changes use **`fork-pack`**.

That one line costs five seconds and saves twenty minutes of “helpful” wrong git. The agent loads branch invariants, stack order, where shared scripts live, and what never belongs on a public fork **before** it touches a file. Fixer gets the same contract via **fix-forks-conflicts** when tag-bump fails—not a free-form “resolve conflicts” prompt.

### Cursor skills as executable policy

Each fork can carry a vendored **`rafaelgaspar-fork`** skill: all seven repos, branch rules, tag-bump flow, mergiraf conflict hints, “change fork-pack not six copies,” checklist before push. A separate **`fork-pack`** skill covers editing the pack itself.

That’s the difference between “smart autocomplete” and **a junior maintainer who read the README**. Agents stop proposing commits to upstream default branches, parallel feat siblings, or planning docs in public repos.

### Upstream PRs with a test ledger

For Xpra and xpra-html5 I maintain `feat-upstream/*` branches and a living doc of **what’s tested vs what belongs in the PR body**. AI is good at filling in test files (`node --test`, Python unit tests) and keeping PR descriptions honest about manual repro steps—but the doc prevents “we shipped to the fork stack” from being confused with “we contributed upstream.”

### Same skills, two surfaces

Cursor and Discord are different UIs for the same idea: **skills are policy, not suggestions**. Tag-bump failures land in a channel Fixer already watches; the webhook text is a work order (`@Fixer` + skill name + guardrails). I’m not pasting stack traces into a blank chat and hoping the model infers `feat/rafaelgaspar` must stay the stack root.

How @mentions, worktrees, signing, and approval gates fit together across agents—not just Fixer—is the subject of the upcoming **Discord Agents** post. The fork fleet was the forcing function: without a named agent and a failure webhook that points at a skill, I’d still be the merge driver for seven repos.

What AI is **bad** at without this scaffolding: choosing correct `workflow_call` checkout refs, remembering that `github.event_name` in a called publish job is still `schedule`, or knowing that seven repos share one rebuild script. Skills and one pack fix that.

## What I ship from the seven forks

| Fork | Upstream | What homelab gets |
| --- | --- | --- |
| homepage | gethomepage/homepage | `ghcr.io/rafaelgaspar/homepage` |
| supergateway | supercorp-ai/supergateway | `ghcr.io/rafaelgaspar/supergateway` |
| xpra | Xpra-org/xpra | GitHub release: full `.deb` set |
| xpra-html5 | Xpra-org/xpra-html5 | Tarball + apt via GitHub Pages |
| otbr-insight | sumitbirla/otbr-insight | `ghcr.io/rafaelgaspar/otbr-insight` |
| http-add-on | kedacore/http-add-on | `ghcr.io/rafaelgaspar/http-add-on-interceptor` |
| moontide | konni-arcadia/moontide | `ghcr.io/rafaelgaspar/moontide` |

Deploy config (Helm, secrets, overlays) stays in a **private** cluster repo. Public forks stay public-safe.

## Lessons (the short list)

1. **Treat forks as a fleet**, not seven hobbies—one pack, one stack pattern, one rebuild script.
2. **One commit per `feat/*` layer**—tag-bump squashes so `git log tag..rafaelgaspar` reads like a changelog.
3. **Delete upstream CI on the fork**—fight fewer YAML merge conflicts forever.
4. **Skip work when git says you’re current**—ancestors of `rafaelgaspar`, not vague “same version.”
5. **Notify on failure, not on skip**—Discord for attempted rebuilds only.
6. **Teach the AI the invariants**—skills beat heroic prompting; “read the skill first” is non-negotiable.
7. **Route failures to a named agent**—Discord + `@Fixer` + **fix-forks-conflicts**, not ad-hoc DMs at yourself.
8. **Prefer upstream PRs for generic fixes**, fork-only layers for homelab-specific glue—and document which is which.

## Sanity check

I still have seven forks. Upstream still releases. What changed is that **a tag bump is a scheduled, idempotent pipeline** with a known conflict playbook, **every coding agent starts from the same skill** instead of rediscovering branch rules, and when the pipeline breaks, **Fixer** gets a structured ping—not me guessing which fork still has a dirty tree.

*Next up (separate post): **Discord Agents**—how Fixer fits alongside the rest of the fleet, and why channels beat email for autonomous homelab maintenance.*

If you’re staring at a homelab full of “we maintain a fork of…” repos, consolidate the *mechanics* before you consolidate the *code*. The forks can stay separate; the workflow doesn’t have to.

---

*Shared tooling: [github.com/rafaelgaspar/fork-pack](https://github.com/rafaelgaspar/fork-pack). Fleet config: `members.yaml` in that repo.*