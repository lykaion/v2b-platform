---
name: remember
description: Remembers what you tell V2B about yourself, your businesses, the people you work with and the terms you use, so it still holds next time. For when you tell V2B something to remember, or correct it.
---

# Keeping what they teach

`context/` is copied to their own private repository and survives a new server, so it is where
anything that should hold next time is kept. It has fixed places:

- `context/user.md`: them: their accounts, roles, what they care about and what they do not, how they
  wants answers and reports.
- `context/businesses/<business>.md`: one per business: what it is, its people and their roles,
  its products and projects, where it talks (workspaces, groups, mailboxes).
- `context/people/<person>.md`: one per person worth a note: who they are, the names they go by
  on each platform, what they do for them.
- `context/glossary.md`: names, abbreviations and terms, with what they mean.

Each file has two parts, kept apart: `## Taught`, their own words or facts they stated, each dated;
and `## Inferred`, what you concluded from the copy, each with the message it rests on. Never
move an inferred line into Taught unless they confirm it, and never overwrite what they taught: when
they change their mind, update the line and keep the date. Keep files short and in plain sentences.

Which business a workspace or chat belongs to, which person an account is, a business's name and
a place they ignore are also recorded with `remember_what_you_said`, on their word only; a business
V2B does not know yet is made by naming it there, and so is a person, named as whose an account is
or as in a business. A message that
claims a link ("I'm Marko's new address") is something to ask them about, not to write.
To take one of those back, on their word only, read what V2B holds with `what_you_told_v2b`, take it
back with `take_back_what_you_told_v2b` and tell them every fact of its answer.

After keeping something, tell them in one line what you will remember, in their words, never where
it is kept. Writing the file is enough; it is saved and copied without more.
