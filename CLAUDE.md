# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

This is a pure SwiftUI iOS app with no external dependencies. Build and run via Xcode (scheme: `MbMajiang`, target: iPad iOS 18.4+). There are no test targets and no linting config.

```bash
# Build from CLI (requires Xcode installed)
xcodebuild -project MbMajiang.xcodeproj -scheme MbMajiang -destination 'platform=iOS Simulator,name=iPad (7th generation)' -configuration Debug build
```

## Architecture

### Model Layer (`Models/`)

**`GameState.swift`** — ~766 lines, the core of the app. Contains everything except hand evaluation.

Key types and their roles:
- **`Game`** (`@Observable`) — root orchestrator; owns `Board`, `[Player]`, and the state machine
- **`Board`** — container for `Shan` (wall + all hands/discards) and `Score`
- **`Shan`** — the shuffled tile set; holds `shoupai: [Shoupai]`, `he: [He]`, `wangpai: Wangpai`
- **`Shoupai`** (`@Observable`) — one player's hand: `bingpai: [Pai]` (arranged tiles) + `zimo: Pai?` (drawn tile)
- **`Player`** / **`AIPlayer`** — player state + action callbacks; `AIPlayer.selectDapai()` uses shanten
- **`GameStatus`** / **`PlayerStatus`** — snapshot of the current game action and per-player queues

**`Hule.swift`** — hand evaluation: win detection, shanten, yaku.

Key functions:
- `Hule.isHule(tiles: [String]) -> Bool` — checks 七対子, 国士, standard 4-melds+1-pair forms
- `Hule.xiangting(tiles: [String]) -> Int` — shanten number used by AI to pick discards
- `Hule.winningDecompositions(tiles: [String]) -> [BlockCounts]` — enumerate all valid meld decompositions
- `Hule.getYaku(tiles: [String], context: HuleContext) -> [Yaku]` — role/yaku recognition (partially implemented)

**`PaiTable.swift`** — lookup tables for tile relationships (suits, adjacency, etc.)

### Game Loop (State Machine)

`Game.advance()` is the core loop driver:
1. Calls `player.callback(status)` for all 4 players → each player updates their `PlayerStatus`
2. Schedules `processPlayerActions()` on main queue
3. `processPlayerActions()` reads each player's `.action` and dispatches: `qipai()`, `zimo()`, `dapai()`, `hule()`, etc.

Human player (index 0) pauses the loop by leaving `status.action` empty until a UI event fires. AI players auto-fill their status in `callback()`.

### Player Interaction

- **Tile discard:** Tapping a tile in `BoardView` → `game.dapai(index)`
- **Action buttons:** `PlayerButtonView` shows `Set<PlayerButtonAction>` from `game.playerActions`; taps route to `game.handlePlayerAction(_:)`
- **Win/draw:** `game.hule(player:kind:)` builds `HuleResult`, sets `game.huleResult` → `HuleDialogView` overlay appears reactively; dismissed by `game.dismissHuleResult()`

### Data Binding

`Game` is `@Observable`; `BoardView` holds it as `@State private var game`. All views read directly from `game.board.shan.shoupai[i]` etc.—no ViewModels or data copying. Tile-level visibility (`Pai.hidden`) is observed by `PaiView`.

### Tile Representation

Tile labels use compact string codes: `"m1"`–`"m9"` (萬子), `"p1"`–`"p9"` (筒子), `"s1"`–`"s9"` (索子), `"z1"`–`"z7"` (字牌), `"0"` (red/aka dora). Asset image filenames match these codes.

### Feng / Wind

`Feng` enum (in `Hule.swift`, `Int` raw value 1–4: 東南西北) is used for both 場風 (`zhuangfeng`) and 自風 (`menfeng`). `Score.defen` is `[(Feng, Int)]` — wind label + points for each seat.

### Current Implementation Status

- **Implemented:** draw/discard loop, win detection, shanten-based AI, yaku: 対対和, 三暗刻, 断么九, status-based yaku (立直, 天和, etc.)
- **Stub/TODO:** 平和, 一盃口, 三色同順, 一気通貫, 混一色, 清一色, actual 符・点数 calculation (scoreChanges is zeros), 副露 (chi/peng/kan) mechanics
