# V2B on your server

This is everything V2B puts on your server, as each version of V2B carries it. Nothing else reaches
your server from the team: the team has no account on it, and its only reach is the version it
signs.

## How a version of V2B arrives

Your server looks for a newer version of V2B by itself, among the versions you chose on V2B's
page on your Mac: finished versions only, or versions being tested too. Each version is signed
by the team, and your server checks that signature against the team's keys it was made with: it
installs nothing whose signature does not hold, and nothing older than what it runs.

A new version replaces the services whose parts changed. An update that does not come up is tried
again, and if it still does not, your server goes back to the version it ran before, which keeps
running; V2B's page on your Mac says so under Updates. You can also ask for an update at once
there, with Update now.

## What runs on your server

Each part of V2B runs as a service of its own, under the name you see it by on your server, and
reaches only what it is allowed to:

- **Copying** (`archive`): holds every key you gave V2B, and copies your Slack, Telegram, Discord
  and mail into V2B's copy on your server, only ever reading on each platform. No other part reads
  a key or opens the copy: the agent and your Mac ask this service for what they need.
- **The agent** (`claude`, and `agent-controller`, which signs it in to Claude): Claude Code, which
  the Claude app on your phone, desktop or the web opens. It answers you from the copy through
  its tools, below, and sees no key.
- **Nightly summaries** (`summaries`), **Record of what was agreed** (`ledger`) and **Weekly
  summary** (`digest`): each reads the copy and writes for the agent: what happened in each busy
  channel, what you confirmed needs you, and each past week as its reports told it.
- **Writing to the repository** (`data-sync`): keeps what you told V2B in your own private
  repository on GitHub, `v2b-data`, written only by your server's own key, so a new server starts
  from it.

### How often your accounts are copied

The first copy begins a minute after the copying service starts. Each account is copied every
five minutes. A copy you ask for may start a minute after the last one began, at the soonest.

### What V2B reads on each platform

V2B only reads. Slack and Telegram are read as you, Discord through a bot on the servers you
chose, and your mailboxes with their passwords. A file a message carries is kept by its name, kind
and size; its contents are not copied.

- Telegram, as you: the sign-in your Mac gives the server reads your own account with reading
  methods only. The client sends no request that sends a message, marks one read,
  sets a status, or joins or leaves a chat; its callable methods are a fixed list, and a test fails
  when one is added. Edits and deletions are copied whatever a message's age, as far as Telegram
  gives them. The pass reads these with reading methods of the same fixed list.
- Slack: the conversations you ticked, with your own key; edits, reactions and deletions are seen
  for a week.
- Discord: each text channel and active thread the bot can read; a channel it may not read is
  left out.
- Mail: each folder you ticked, read without marking anything read or moving anything.

## What the agent may do, and what it asks you first

The agent's settings are part of each version and cannot be changed on your server. Its tools
that only read, and copying now, run without asking you. The two that change what V2B holds,
remembering what you said and taking it back, ask you first in the Claude app, each time. The
agent writes only its own reports and what you ask it to remember, and nothing is ever sent from
it to any platform.

## The agent's tools

What the Claude app shows at each of the agent's calls: its tools, and the commands it runs.

| Tool | What it does for you |
|---|---|
| `search_messages` | Searches every copied message, in any script, with or without accents. |
| `read_thread` | Reads a whole thread, from the message it began with. |
| `read_conversation` | Reads what was said in a channel, chat or folder over a time. |
| `messages_by_person` | Gives what a person wrote, across all their accounts. |
| `what_may_need_you` | Gives the conversations that may wait on you. |
| `list` | Lists every account and conversation V2B copies, and how each copy stands. |
| `copy_status` | Says which accounts cannot be copied now, and what you do about it. |
| `copy_now` | Copies an account now, rather than at its next copy. |
| `remember_what_you_said` | Remembers what you said: a conversation's business, who an account is, a name. Asks you first. |
| `what_you_told_v2b` | Gives everything V2B holds of what you told it. |
| `take_back_what_you_told_v2b` | Takes back something you told V2B. Asks you first. |
| `v2b-search` | Searches the messages' text for words or a pattern. |
| `v2b-day` | Gives one channel's day, or a run of days. |
| `v2b-dates` | Turns words such as "last week" into the dates they mean. |
| `v2b-who-took-part` | Says who was in a message, and how. |
| `v2b-message-history` | Gives each change to a message, in order. |
| `v2b-as-received` | Gives one change to a message as its platform sent it. |
| `v2b-what-is-copied` | Lists every account and conversation copied. |
| `v2b-query` | Asks the copy a question in SQL, changing nothing. |
| `v2b-businesses` | Lists, makes and renames your businesses. |
| `v2b-people` | Lists the people you named, their accounts and businesses. |
| `v2b-set-business` | Sets the business a conversation is in. |
| `v2b-your-accounts` | Lists your own accounts. |
| `v2b-what-may-need-you` | Gives the conversations that may wait on you. |
| `v2b-now` | Gives what stands as a conversation starts. |
| `v2b-status` | Gives how each account's copy stands. |
| `v2b-copy-now` | Copies an account now. |
| `v2b-summarize` | Writes the summaries of a day's channels. |

## Where what you told V2B is kept

What you told V2B, the businesses, who each person is, what it should remember, is kept in your
own private repository on GitHub, `v2b-data`, which only your server's own key writes. A new
server reads it back, so nothing you taught V2B is lost with a server.

## Seeing what ran

- V2B's page on your Mac shows each service, whether it runs, and each account's copy; `v2b
  status` in Terminal on your Mac says the same.
- The agent keeps a record of each question you asked, each tool it called with what the tool
  answered, and each answer it gave, on your server, beside its own files.
