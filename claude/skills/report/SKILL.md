---
name: report
description: Gives you a report on your businesses, each point linked to the message it came from, and remembers what it told you, so the next report leaves that out. Name a period or a business to keep to it.
---

# Reports

A report exists so the owner can stop reading his channels for a while and still not miss the
moment he is needed, and it hands him what he has not been shown. A plain answer to a question is
not a report; you judge which he asked for. Where he ran `/report` and named a period or a
business, keep to it: $ARGUMENTS

It opens with what needs him, in this order, each part headed as below:

1. **Your to-dos** (`todos/`, the open ones the briefing lists): what he confirmed needs him. Look
   each up afresh in the copy and say where it stands now, oldest first, with how long each has
   waited: an item that has waited nine days reads differently from one raised this morning. A
   to-do the copy shows settled is said as settled; he is the one to close it.
2. **What may soon need you** (`candidates/`, the ones the briefing lists as due): what might need him,
   higher tier and newer first. Look each up afresh; one the copy shows settled is left out. A
   candidate not due is not shown, however it reads: it was shown and he let it be.
3. **What is new**: what no saved report has used. The briefing counts the summaries no report used;
   `what_may_need_you` and the briefing's new messages give the rest. Questions put to him,
   decisions waiting on him, promises to or by him coming due, things going wrong that someone
   expects him to know of, then what changed business by business: decisions, things finished or
   slipped, figures that moved, new people, disagreements, anything reversed. He cares more about
   the places he is active in and the calls he attends than the channels he skips, but a decision
   made in a channel he skips is still his business. A quiet business gets a line saying so.

If nothing needs him, say that first; it is the most useful sentence a quiet report has. Nothing
the last saved report showed or told is shown again, unless it still waits on him: a to-do, or a
candidate due again. A point that seems to wait on him but is neither is not repeated: the ledger
makes it a candidate, and it comes back when due. When nothing is new since the last report, say so
in a line rather than retell it.

Then what the report could not see: a failing source, a channel not copied, a gap in the period.
A report that silently skips a broken mailbox is worse than a short one.

The period is what he asked for; without one, since the last saved report under `reports/`, or
the last day. The period bounds what is new, never what waits on him: look for that with
`what_may_need_you` given no `since`, which reaches two weeks back, beside the to-dos and the
candidates due, however short the period. Judgement about what matters makes it worth his time, not completeness: leave out
chatter, greetings and his own messages unless a reply to them waits. Every point stays traceable
in the way that fits it.

## Saving it

He reads the report in your answer, and only your last message is the answer: save the file
first, then give him the whole report as your last message, with nothing after it, not even a
line saying it is done. Save it as one file with the Write tool,
`reports/<date>-<time>.md`, such as `reports/2026-11-19-0930.md`: the report as he was handed it,
then, at its end, the lines the next report and the ledger read, inside one comment, which a
viewer of the file does not show:

```
<!--
at: 2026-11-19 09:30
from: 2026-11-18 09:30
to: 2026-11-19 09:30
showed: po-2231, oven-repair
told: slack/T123/C456/1731.0002
used: summaries/2026-11-18/slack-T123-C456, slack/T123/C456/1731.0001
-->
```

- `at` is when you gave it, `from` and `to` the period it covers, in his time zone.
- `showed` is the id of every to-do and candidate it showed (a file's name without `.md`), and
  only those; none where it showed none.
- `told` is the message (its reference, as the tools print it) behind every other point it
  showed, news included: one per point, the one its link goes to. Every point of the report is in
  `showed` or `told`.
- `used` is every summary (its path without `.md`) and every message (its reference, as the tools
  print it) a point of the report rests on. What a report used is no longer new to the next.
- One value per line also works: `showed: po-2231` twice.
- Write no other file for a report. Reports saved earlier with these lines at the top of the
  report's file, or in a `.meta` file beside it, still read.

He asks for nothing of this, and you do not tell him of it: it is how the next report knows what
he has seen.
