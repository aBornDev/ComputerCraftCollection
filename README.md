# ComputerCraftCollection

A collection of ComputerCraft (CC: Tweaked) scripts, mostly for turtles.

## Installation

Run this on the computer or turtle:

```
wget run https://raw.githubusercontent.com/aBornDev/ComputerCraftCollection/main/install.lua
```

This downloads every program plus the shared library `lib/turtleUtils.lua`, which the turtle
programs need. Later you can update with `install` (or `install <branch>` to test a branch).

## Programs

### builderQuarry

Builds a builder setup, waits until it is done, breaks it down, moves one chunk and starts over.

```
builderQuarry <auto|build|pickup|check|movechunk|collect>
```

- `auto` runs the full cycle forever: check, pickup, movechunk, build, collect.
- Without a task the program asks for one.
- Between 07:30 and 08:00 (server time) the program stops. Change `STOP_WINDOW` to adjust.
- The builder counts as done once the chest in front of the turtle has been empty for 60 seconds.

| Slot | Contents |
| ---- | -------- |
| 1    | Container with fuel |
| 2    | Builder |
| 3, 4, 6 | Setup parts (see `SLOT` in the script) |
| 5    | Frame blocks (6x) |
| 15, 16 | Chunk loaders |

### autoDigitalMiner

Builds a Mekanism digital miner setup, keeps the miner running, and once it is done moves
64 blocks forward and starts over.

```
autoDigitalMiner [check|build|pickup]    (default: check)
```

| Slot | Contents |
| ---- | -------- |
| 1    | Container with fuel |
| 2    | Digital miner |
| 3    | Quantum entangloporter |
| 4    | Teleporter |
| 5    | Ender chest for the loot |
| 6    | Chat box |

When the miner cannot be found, the turtle places a teleporter and stops.

### betterExcavate

Digs a rectangular hole, three layers per pass, upwards or downwards.

```
betterExcavate [length] [width] [depth] [l|r] [u|d]
```

Missing arguments are asked for. Slot 1 holds a container with fuel, slot 2 an ender chest that
receives the mined items. When the turtle hits an unbreakable block (e.g. bedrock), it finishes
the current layer and returns home.

### touchScreen

Shows buttons on a monitor. The `spawner` button sends `on`/`off` on modem channel 3.
Needs a monitor and a modem.

### claudeChat

Chat with Claude from any computer or turtle through the Anthropic API.

```
set claude.key sk-ant-...     (once; get a key at console.anthropic.com)
claudeChat
```

Commands: `/reset` starts a new conversation, `/usage` shows the tokens used, `/exit` quits.

Optional settings (`set <name> <value>`):

| Setting | Default | Meaning |
| ------- | ------- | ------- |
| `claude.model` | `claude-opus-5-5` | Model to use |
| `claude.effort` | `low` | `low`, `medium`, `high`, `xhigh` or `max`: higher thinks longer and costs more |
| `claude.max_tokens` | `1024` | Maximum length of one answer |

Notes:

- Needs the HTTP API enabled in the CC: Tweaked config (on by default).
- Every question is a paid API request. The whole conversation is sent each time (with prompt
  caching), so use `/reset` for a new topic.
- The key is stored on the computer. On a shared server, admins and anyone who can open the
  computer can read it.
- If Claude declines a request, the API retries it on another model automatically
  (server-side fallback).

### remoteLoadTest

Checks that running a program straight from the web works:
`wget run <raw url> [parameter]`.

## Development

The turtle programs share their helpers (movement, fuel, logging, time window) in
`lib/turtleUtils.lua`. Moves are retried when a mob or falling block is in the way; when a move
still fails the builder programs stop with an error instead of continuing from the wrong position.

Run `luacheck .` locally; GitHub Actions runs it on every push.
