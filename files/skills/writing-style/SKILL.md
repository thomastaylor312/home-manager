---
name: writing-style
description: Load Taylor's past writing samples when drafting content he will share under his own name — blog posts, design docs, RFCs, proposals, emails, Slack messages, PR descriptions, READMEs, release notes, or any first-person prose. Triggers on phrasings like "write a post/doc/email", "draft a response", "help me write…", "put together a write-up", "write this up for me", or any task where Taylor is the author. Skip for code, commit messages, or internal working notes the user won't publish.
---

# Writing in Taylor's Voice

When drafting content that Taylor will share under his own name, model the tone, sentence rhythm, and structural habits in `samples/` — do not just describe his style from memory. Pick samples that match the shape of the piece being written, read them in full, then draft.

## Step 1 — Pick samples by the kind of writing

| Writing type | Primary sample(s) |
|---|---|
| Opinion piece / strong take / "why you should think twice about X" | `samples/blog-crds.md` |
| Revisiting / reassessing a topic after more experience | `samples/blog-nix.md` |
| Structured technical review (tradeoffs, pros/cons, feedback) | `samples/blog-rust.md` |
| Generic technical blog post | `samples/blog-nix.md` + `samples/blog-rust.md` |
| Design doc, RFC, or technical proposal | `samples/blog-rust.md` for voice — **then see Step 2** |
| Email / Slack / PR description / short-form | `samples/blog-crds.md` as the lightest — **then see Step 3** |

Load 1–2 samples, not all three. Read each chosen sample end-to-end before writing a single sentence.

## Step 2 — Design docs: ask before drafting

If the piece is a design doc, RFC, architecture proposal, or similar technical specification, **stop before drafting** and ask Taylor:

> The blog samples give me Taylor's voice, but design docs have their own shape and conventions. Do you want me to pull in past design docs as closer stylistic references? If so, tell me where to find them — for example:
> - A Notion workspace or specific page (use the Notion MCP tools)
> - Google Drive / Docs (via a Drive MCP if configured)
> - An internal wiki or Confluence
> - A local directory or repo path I can read
> - Public URLs I can fetch
>
> Or skip and draft from the blog samples alone.

Wait for direction. Do not assume a connector is available — Taylor will say which one to use.

## Step 3 — Short-form: check fit

Blog samples over-formalize short writing. Before drafting a Slack message, email, or short PR description, consider asking:

> I have Taylor's long-form blog samples loaded, but those are wordier than a typical Slack/email. Want me to draft as-is and trim, or do you have a short-form example I should load first?

Skip the question if the user has clearly signaled urgency ("just draft it", auto mode on a trivial message, etc.) and trim aggressively instead.

## Step 4 — Draft, then self-check

After drafting, reread one chosen sample and compare. Ask:

- Does my draft use the same sentence length and rhythm?
- Does it use the same signposting habits (e.g. "Let's dive in:", "Here's how I want you to think about it:", parenthetical asides, rhetorical questions that tee up the next paragraph)?
- Does it ground claims in specific examples and numbers the way the sample does?
- Would a reader who knows Taylor's blog think he wrote it, or would it read as generic LLM prose?

Revise until it matches. Do **not** copy phrases verbatim — the goal is voice, not plagiarism of oneself.

## Notes

- Samples live at `samples/` relative to this file. Read them with the Read tool before drafting.
- If Taylor points you at a new sample source during a session, read it but do not write it into this skill unless he asks. New permanent samples are added by dropping files into `samples/` in the home-manager repo.
