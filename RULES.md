# Word Link — RULES

The authoritative source of truth for Word Link. The engine must enforce
every rule below; if the implementation diverges, fix the implementation.

## 1. Objective
Swipe through adjacent letter tiles to spell every hidden word on the
board. Clear boards to advance (Journey), beat the clock (Blitz), or play
at your own pace (Relaxed).

## 2. Setup
- A square grid of letter tiles is dealt: 3×3 (Rookie), 4×4 (Wordsmith),
  or 5×5 (Genius, Pro).
- A hidden word list is generated per board: 3 words (3×3), 4 words (4×4),
  6 words (5×5).
- Every hidden word is guaranteed placeable as an 8-way adjacent path:
  words are drawn onto the grid during generation, then empty cells are
  filled with random letters.
- Journey mode: 60 levels; levels 1–20 use 3×3, 21–40 use 4×4, 41–60 use
  5×5. Level boards are deterministic (seeded by level number) so every
  player gets the same board.
- Blitz mode: 120 seconds on the clock, endless boards.
- Relaxed mode: no timer, endless boards.

## 3. Turn order
Single-player game. One continuous session: swipe → evaluate → next
swipe. There are no turns between players.

## 4. Legal moves
- Start a swipe on any tile while the board is in the `playing` phase.
- Extend the swipe to any of the 8 neighboring tiles of the current tile.
- Backtrack: swiping back onto the second-to-last tile removes the last
  tile from the path.
- A tile may appear at most once per swipe.
- Releasing the finger submits the spelled word.

## 5. Illegal moves
- Swiping while the board is dealing, evaluating a word, celebrating a
  clear, paused, or finished: input is locked.
- Jumping to a non-adjacent tile: the jump is ignored.
- Re-entering an already-used tile (except backtracking): ignored.

## 6. Captures
Not applicable — no captures in Word Link.

## 7. Special rules
- Words count forwards OR backwards (CAT and TAC both link "CAT").
- Shuffle: regenerates the letter layout for the SAME word list; all
  words remain findable. Free, unlimited.
- Hint: reveals the next hidden letter of the first unfinished word chip.
  Free tier: 3 hints per board. Pro: unlimited.
- Blitz: when all words on a board are found, a fresh board is dealt
  immediately (+50 bonus) and the clock keeps running.
- Pause freezes all engine timers (deal, reveal, blitz clock); resume
  re-arms the current phase via the watchdog.

## 8. Scoring
- Each found word: word length × 10 points.
- Board clear bonus: +50 (Blitz) or 25 + 5 × grid size (Journey/Relaxed).
- Blitz score is the session score; the best Blitz score persists.

## 9. Winning conditions
- Journey: clear all 60 levels → "Journey complete".
- Blitz: there is no final win; the session ends when the clock hits zero
  and the score stands.
- Relaxed: endless; the player ends the session whenever they like.

## 10. Draw conditions
Not applicable — single-player.

## 11. AI strategy
Not applicable — no opponents or bots in Word Link.

## 12. Edge cases
- If board generation fails to place all words after 80 attempts, the
  ultra-safe fallback lays words in straight rows (always placeable).
- Shuffle re-placement retries 80 times; on total failure the board is
  left unchanged (astronomically unlikely).
- App backgrounded mid-reveal/deal: timers are cancelled; the watchdog
  resumes the phase on return. No stuck state is possible.
- A swipe that spells nothing: the preview shakes and the path clears;
  no score change.
- Journey progress (current level) persists across sessions.

## 13. Test cases
- Determinism: Journey level N generates the identical board and word
  list on every run (seed = N × 7919).
- Placeability: every generated word has a valid 8-way path on the
  board (guaranteed by construction; test samples seeds).
- Reverse words: submitting a word backwards marks it found.
- Backtracking: swiping back removes the last tile, no sound spam.
- Invalid swipe: miss counter increments, preview shakes, score unchanged.
- Blitz clock: reaches 0 → phase `over`, exactly one `gameOver` event.
- Reveal: after a find, phase returns to `playing` once the reveal
  timer completes; watchdog recovers if the timer dies.
- Hints: free tier decrements 3 → 0 and then refuses; Pro never refuses.
- Player names: encode/decode round-trips order; legacy keys migrate.
