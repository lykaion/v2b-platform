# V2B server

This repository is everything the team puts on your server. Nothing else reaches it: the
team has no shell there. A change ships as a signed release.

## How a change arrives

Every hour, at a moment varied by up to ten minutes, a timer on your server
(`v2b-update.timer`) runs `v2b server-update`, which looks for a newer release of V2B.
A release is signed by the team; the server checks the signature against the key built into
the program and installs nothing that fails it, or whose files do not match the signed list.
It only ever moves forward: an older release, or the one already installed, changes nothing.

Each release is unpacked whole beside the one running, as a generation under
`/usr/local/lib/v2b/gen/`, and `/usr/local/lib/v2b/current` is switched to it in one step.
The system packages listed in `deploy/packages` that the server lacks are installed first, then
the services, settings and commands that differ from the previous generation, and only the
services whose files changed are restarted. A new program, or a package installed, restarts
`v2b-archive.service`, the one service that runs it; a service run by a timer is never
restarted, it picks the change up on its next run. Twenty seconds after, every service
that was running before must be running again; if one is not, the previous generation is put
back and restarted, and the log says `rolled back`. The previous generation is kept; older ones
are deleted.

## The archive service
The archive service copies your Discord servers, your Telegram chats, your Slack conversations, your mailboxes and your Granola meetings into its database, read-only on the
platform. The database is `v2b.db` in the service's state directory, owned by the archive service's user;
the assistant never opens it and asks the service for every read and every write it is allowed.
A reading is added and never changed: an edit or a deletion is a new reading, and what the
platform answered is kept as received beside the typed row. Which business a server, channel or
chat is about is a row of its own, so moving one writes no reading and moves no file.

One service, `v2b-archive.service`, holds every key and runs every mirror. It reads
`/etc/v2b/archive/` when it starts and again on `systemctl reload v2b-archive`, and holds
one connection per file there, named by the file: `telegram`, `discord`, `granola`, `slack-<name>`,
`mail-<name>`. Discord, Granola, mail, Slack and Telegram each get a pass every five minutes, the first a minute after the
service starts; one connection's pass never overlaps itself, and one that fails is noted in
that connection's status and tried again five minutes later without stopping any other. If the
service stops for any reason, systemd starts it again.

The service runs fenced, with the lines the agent's service carries: the file system read-only but
its own state directory, no home directories (the agent's workspace is out of its sight), no
capability, no new privilege, a filtered set of system calls. Its network stays open, since that
is how it reads the platforms.

- Discord: one pass over each Discord server the bot is in, fetching only what is new since the
  last pass in its text and announcement channels and their active threads; a thread is a
  channel of its own, under its parent channel.
  Not fetched: archived threads, forum and media channels, edits and deletions between passes,
  and attachment files. A channel the bot may not read is left out and counted as skipped, not
  as an error. Each pass first asks Discord whether the bot's Message Content
  Intent is on. If it is, every page is copied as it arrives, even one whose messages carry no
  text. If it is off, the pass asks for no message, copies none and advances no mirror, stores
  the servers, channels and threads for the list, counts none as copied, and fails with a
  message that names the switch and the Developer Portal's Bot page, in the status and, once,
  in the log; once the intent is switched on the messages are copied, each a first reading
  with its text and none an edit. If Discord cannot be asked, the pass copies nothing and fails.
- Granola: one pass over the folders the owner ticked, or over the whole account when it has
  none, read with the key the owner made in Granola (Settings, Connectors, API keys, Personal
  notes only). A meeting is the utterance; its notes and its transcript (speaker and time per
  segment) are its readings, so a changed note or transcript is a new reading, and the people
  the meeting lists took part. A pass lists each ticked folder for meetings updated since its
  cursor (an hour back, so a late change is seen), reads each whole, and requests only by GET:
  nothing is written, marked or sent in Granola. A meeting moved to another folder is stored at
  its new home and a deleted one as deleted. Granola lists only meetings that have a summary
  and a transcript, so a meeting is seen once it has both. A key Granola refuses fails the
  pass and the status names it as the key.
- Slack: one pass over the conversations the owner ticked, read with the owner's own key. It
  copies the workspace and its accounts, then each ticked conversation from its cursor: a
  message and each reply of its thread, as Slack sent them, a reading for every new message and
  for an edit, a reaction or a deletion the pass sees. A pass reads a conversation again from
  seven days back, so an edit, a reaction or a deletion of a message is seen while it is that
  recent. A reply is found by asking, not by re-reading every thread: the history gives a
  thread's first message with its newest reply and its count, and one search of the thread
  replies the key can see (`search:read`, once a pass for the workspace) names the threads
  with a reply newer than the last good search; a thread whose reply the copy lacks, or whose
  count fell, is read whole again, its first message and its replies, whatever the age of the
  first message. A quiet conversation costs one history call and reads no thread. Not seen: an
  edit or a reaction on a message older than seven days, or on a reply, until a new reply makes
  its thread be read again; a search that fails fails the pass and leaves the search where it was. A file is kept as its name, kind and address; its
  bytes are not fetched. Nothing ticked copies nothing. A key Slack refuses fails the pass and the status names it as the key.
- Telegram, as the owner: the sign-in the Mac gives the server (`TELEGRAM_SESSION`) reads the
  owner's own account with reading methods only: who the account is, its dialogs, and message
  history and messages by id. Nothing is sent, nothing is marked read, no status is set, and no
  chat is joined or left; the client's callable methods are a fixed list, and a test fails when
  one is added. The owner's account is the source, each chat a place (a person's id, `-id`
  for a basic group, `-100id` for a channel or supergroup) and each message an utterance. A pass copies
  every ticked chat from its cursor, a page at a time with the cursor committed, one reading per
  message. Edits and deletions are readings whatever the message's age, as far as Telegram gives
  them: the pass keeps Telegram's own place in its numbered events (one for the private chats and
  basic groups together, one for each channel and supergroup) beside the cursors, reads what
  happened after it, and asks again, by number, for the ticked chats' messages it names; one that
  now differs is stored as an edit (at its own edit date) and one Telegram answers as gone as a
  deletion (at the pass's time, since Telegram does not say when). A deletion in the private
  chats and basic groups names the number alone, and the pass finds the chat from its own tables.
  Where Telegram no longer replays that far, or refuses the place kept, every message held of the
  chat is asked for again by number, oldest first, with its progress kept. That takes three more
  reading methods (`updates.getState`, `updates.getDifference`, `updates.getChannelDifference`),
  in the same fixed list. A change to a message's reactions carries no numbered event, so it is
  seen only for a chat's newest 100 copied messages, asked for again on every pass. A chat whose
  events a pass could not read (it was not ticked, or not listed) is swept the same way when it is
  back. What it cannot see is a reaction to an older message. A wait
  Telegram asks for of up to 90 seconds is waited out, three times at most for one request; a
  longer one ends the pass with the cursors kept, and the next pass
  resumes. A session Telegram has ended fails the pass with "Telegram refused the sign-in V2B
  was given (...). Sign in to Telegram again from V2B on your Mac.", which the Mac reads as the one reason to ask for a
  new sign-in. Reactions are kept as changes; attachment files, pins and topics are not copied.
- Mail, over IMAP with the mailbox's password: the mailbox is the source (known by its short
  name), each ticked folder a place and each message an utterance. The server is reached by
  `EXAMINE`, `UID SEARCH` and `UID FETCH` of `BODY.PEEK` alone, so nothing is stored, marked or
  flagged on it, and flags (read, starred) are not copied. A folder is copied newest first, a batch
  to a transaction with the UIDs it placed, so a pass that stops goes on from the UIDs not yet
  copied. A message shown by two ticked folders (Gmail's labels and All Mail) is one utterance, known
  by its `Message-ID` (one without is known by its folder and UID) and filed under the folder it
  was first seen in. A message gone from every ticked folder holding it, or whose folder was
  remade under a new UIDVALIDITY and does not hold it, is stored as deleted; a folder unticked
  deletes nothing. The raw kept is the headers and the text parts as received; the other parts are
  kept by name, kind, size and where on the server they are, never their bytes, and a message
  larger than 32 MB is kept by its headers alone. Who wrote a message, was sent it (To) or
  was copied (Cc) is read from its headers; a reply is read from `In-Reply-To` and `References`.
  Gmail's web client opens a message by its `Message-ID`. The mailbox's business is a link in
  the database, made by `assign`.

The service answers on one socket, `/run/v2b/archive.sock`, owned by the archive service's user and
the group `v2b`, so only the assistant and `root` can connect to it. Each request and each
answer is one line of JSON: `status` gives every connection, whether it is copied and running,
when its last pass started and ended, whether it went well and what it copied; `sync` runs one
connection's pass now, or waits for the one already running, and says what it stored per
place, or that it was not copied yet; `list` shows what one connection could copy, without copying anything: the source and
each channel, group, folder or server in it, and whether it is chosen; `reload` reads the
settings again. Each request is answered only to the callers allowed it: `list`, `reload` and
the owner's word as a whole to `root` alone, the agent's reads and writes to the assistant, and
any other caller is refused in one sentence naming the request. No answer holds a key. Each
request is one line in the journal, with the caller's user id and whether it went well, never
what was asked or answered.

Their settings are files in `/etc/v2b/archive/`. The archive service runs as a user of its own, and
the assistant cannot read their keys: only the archive service and `root` can open that folder, and
every install from this repository puts its owner and permissions back, along with those of
the archive service's state, where the database is. One `KEY=value` per line, no quotes, `#` for
comments:

- `slack-<name>.env`, one per Slack workspace, named by its team id in lower case:
  `SLACK_USER_TOKEN`, the owner's own key (`xoxp-…`), and `CHANNELS`, a comma list of the
  conversation ids ticked (public and private channels, group direct messages and direct
  messages); without it nothing is copied. The key asks only read scopes, and no bot is made or
  used. The workspace's business is a link in the database, made by `assign`, not a line here.
- `granola.env`: `GRANOLA_API_KEY`, the owner's key (`grn_…`), read by `v2b-archive` alone.
- `granola-folders.env`: one `<folder id>=` per folder ticked, and `unfiled=` for the meetings in
  no folder; an account with no folders is copied whole and needs no line. The account's business
  is a link in the database, made by `assign`, not a line here.
- `discord.env`: `DISCORD_BOT_TOKEN`.
- `discord-guilds.env`: one `<server id>=` per server ticked; nothing else is copied. The
  server's business is a link in the database, never a line here.
- `mail-<name>.env`, one per mailbox: `MAIL_HOST`, `MAIL_USER` and `MAIL_PASSWORD`; optionally
  `MAIL_PORT` (993 by default), `MAIL_TLS` (`tls`, TLS from the start, by default, or
  `starttls`) and `FOLDERS`, a comma list of folder names. The mailbox's business is a link in
  the database, never a line here.
- `telegram.env`: `TELEGRAM_SESSION`, the owner's Telegram sign-in as one base64 line (gotd's
  session), read by `v2b-archive` alone. Any other key in it is not read.
- `platform-addresses.env`, on a test server only: `slack`, `discord` and `granola`, each the
  address of a stand-in for that platform, read in place of the platform's own. It is read once,
  when the service starts, and only when `root` owns it and no one else can write it; a file
  refused is said in the journal and the status, and those three platforms copy nothing until it
  is put right. Every face of the status says which platforms a stand-in serves. The reads
  allowed for each platform are the same whatever its address.
- `telegram-chats.env`: one `<chat id>=` per chat ticked; nothing else is copied. A chat's
  business is a link in the database; a line holds one only when it was given before the chat was
  copied, and the next pass sets the link.

Only the service opens
the database, holding its lock in `/var/lib/v2b/archive/`, and it writes one pass at a time.

`sudo /usr/local/lib/v2b/bin/v2b connect` writes them for you, and running it again replaces
a key or a business. Once it has written a file it asks the service, over its socket, to read
the settings again and, where a pass follows, to run that pass, and prints what the pass
copied; no service is restarted. `slack <name>` sets a Slack workspace's key, the conversations
ticked afterwards with `v2b choose slack <name> <id,...>`, which runs a pass; `slack-workspace <team id>
<business>` links a workspace to a business;
`telegram` sets the Telegram sign-in and runs a pass; `discord` sets the Discord key and runs a pass;
`granola` sets the Granola key and runs a pass, the folders ticked afterwards with `v2b choose granola <folder>`, one folder (or `unfiled`) at a time; `granola-source account <business>` assigns the account;
`telegram-group <chat id> <business>` assigns a chat; `discord-server <server id> <business>`
assigns a server and runs a pass; `mail <name> <user> <host> <port>` sets a mailbox's password,
its folders chosen afterwards with `v2b choose mail <name> <folder,...>`; `mail-box <name> <business>`
links a mailbox to a business. Port 143 uses `starttls`; a password
with a character other than ASCII is refused, since IMAP's sign-in cannot carry it. It asks for the key
or password hidden at the terminal, or reads it from its standard input when a script feeds it;
a key is never typed on the command line. Typed by hand, run it inside the `ssh` session rather
than as the command `ssh` is given, so the terminal hides the key as you type it.

The assistant can run a pass now rather than wait five minutes, through the socket; it asks
the service, which holds the keys, and never reads them itself.

What each connection has fetched so far is kept in `/var/lib/v2b/archive/`; it holds no keys.

| In this repository | On your server |
|---|---|
| `units/` | `/etc/systemd/system/` |
| `claude/managed-settings.json` | `/etc/claude-code/managed-settings.json` |
| `claude/managed-mcp.json` | `/etc/claude-code/managed-mcp.json` |
| `claude/commands/` | `/etc/claude-code/.claude/commands/` |
| `workspace/CLAUDE.md` | `/etc/claude-code/CLAUDE.md` |

All of these are root's: the assistant reads them and cannot change them. Claude Code reads
`/etc/claude-code/CLAUDE.md` as managed memory and the commands beside it as managed commands.
`managed-mcp.json` names the one tool server the assistant's sessions load, `v2b mcp`: it runs
as the `v2b-agent` user and asks the archive service over the same socket as the commands. The
managed settings allow each of its tools by name, so a call to one runs with no prompt and no
review, and allow no other server.

## The door to the assistant

`v2b-remote-control.service` runs all the time, as the `v2b-agent` user, in `/home/v2b-agent/workspace`:
it is `claude remote-control`, which lets the Claude app on your phone, desktop or the web
open the assistant on your server. It restarts five seconds after any stop. It cannot see the
mirrors' keys (`/etc/v2b` and `/var/lib/v2b/archive` are hidden from it) and what it writes is
private to it (`UMask=0077`). The rest of the file system is read-only to it but its home, it
gains no privilege (no sudo), and the kernel's controls are out of its reach; each line in the
unit file says why it is there. A change to its unit file restarts it on the next deploy.

Claude Code itself is root's, in `/usr/local/lib/claude-code`: root installs it, and
`v2b-claude-update.timer` updates it once a day, restarting the door only when the version
moved. Claude Code's own updater is off, so the assistant runs only the copy root installed.

## Seeing what ran

- What changed and who changed it: `git log` in this repository.
- Whether it was installed: `/var/log/v2b/deploy.log`, one line per event (`installed`,
  `update failed`, `rolled back`, `refused signature`, `nothing new`). You can also ask the assistant whether the
  last deploy worked; it can read that file.
- The release installed: the generation `/usr/local/lib/v2b/current` links to.
- What the archive service did: one journal, `journalctl -u v2b-archive`, with a line for each
  pass and its counts, each failure, and each request to the service with the caller's user
  id. `/usr/local/lib/v2b/bin/v2b status` shows each connection: copied or not yet, its last pass,
  whether it went well and why not; the assistant can run it for you.
- What the assistant was asked and did: `/home/v2b-agent/use-log/`, written by the hooks in
  `claude/managed-settings.json` from what Claude Code hands each hook, one JSON line per
  event. `prompt.jsonl` holds each question; `tool.jsonl` each tool call, its input and what it
  returned or the error, a returned value over 8192 characters, serialised, kept as its first 8192 characters
  with `truncated: true`; `stop.jsonl` each answer, with the path of the session's
  transcript. `run` is `session` for a turn from the app or the desk, or the name in
  `V2B_RUN` for a background run that sets it. The lines of one turn share `prompt_id`.
- To look for a release now rather than wait: `sudo systemctl start v2b-update.service`.

## From your laptop

V2B Setup is the program you run on your Mac: it sets the server up with you, connects your
channels and shows what is running, and asks for every key in a hidden window. The same program
is installed on the server as `/usr/local/lib/v2b/bin/v2b`, which is what the commands above run.

## Review before a change takes effect

Not turned on. Every change is still in this repository's history with the team's name on it, and the
assistant can explain any of it.

## Test

`deploy/test-hooks` runs each hook's command on sample input and checks the line it writes; it
needs no network. The archive service's tests are the program's own.

## The agent's tools

Installed in `/usr/local/lib/v2b/bin/` for the assistant to run as `v2b-agent`, with no `sudo`; each
is the program, `/usr/local/lib/v2b/bin/v2b`, or a link to it under the tool's name, and none
is a service. `v2b sync` and `v2b status` (also reached as `v2b-sync` and `v2b-status`) ask the archive service over its socket, `/run/v2b/archive.sock`, and
name a connection by its name: `telegram`, `discord`, `granola`, `slack-<name>`, `mail-<name>`.

| Tool | What it does |
|---|---|
| `v2b-grep` | Searches the messages as they are now (edits applied, deletions left out), matching across Cyrillic and Latin and with or without diacritics; narrows by business, platform, source, channel, author and time window; `--around`, `--full`, `--count`. Exit 1 on no hit, 2 on a bad argument. |
| `v2b-dates` | Turns a phrase (today, last week, this month, last N days, since a weekday, a date or two) into `since=` and `until=` in UTC, its edges local midnights. |
| `v2b-day`, `v2b-who`, `v2b-history`, `v2b-raw`, `v2b-held`, `v2b-query` | Read what the service holds: a channel's day, who was in an utterance, an utterance's readings, one reading as the platform answered it, every source and place held, a free read-only query. Asked of the service; none opens the database. |
| `v2b-business`, `v2b-people`, `v2b-assign` | Write the businesses, the people and the business a workspace, channel or chat is about, on the owner's word in chat. |
| `v2b sync <connection>` | Runs one pass of that connection now and waits for it: says the pass started, says what it stored per place or that nothing is new, and says when a pass was already running and it joined that one. Exit 0 on a good or joined pass, 1 on a failed pass, an unknown connection or a service it cannot reach (one line naming the socket), 2 on a bad argument. |
| `v2b status` | One line per connection: its name, business, not copied yet or its last pass time, ok or the error, and the pass's counts. `--json` prints the service's answer, its last line without the transport's `done` (`ok`, `wire` and `connections` in it). |
