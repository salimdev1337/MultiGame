# Flutter Sudoku Game – Task Breakdown

This file is written **for Claude / AI coding assistance**.
Each task is intentionally small, atomic, and sequential.
Claude should complete tasks **top‑to‑bottom**, without skipping steps.


## PHASE 1 – Sudoku Core Engine (CRITICAL)

### T1.1 – Sudoku Cell Model

* Create `SudokuCell` model
* Properties:

  * value
  * isFixed
  * notes (Set<int>)
  * isError

### T1.2 – Sudoku Board Model

* Create `SudokuBoard` model
* 9x9 grid of `SudokuCell`
* Helper methods:

  * getRow()
  * getColumn()
  * getBox()

### T1.3 – Sudoku Validator

* Validate rows, columns, and boxes
* Detect conflicts
* Return error positions

### T1.4 – Sudoku Solver (Backtracking)

* Implement solver algorithm
* Used for:

  * solution validation
  * hints
  * puzzle generation checks

### T1.5 – Puzzle Generator

* Generate full valid board
* Remove cells based on difficulty
* Guarantee **unique solution**

---

## PHASE 2 – Classic Mode (FIRST GAME MODE)

### T2.1 – Classic Mode Screen UI

* 9x9 grid layout
* Number pad (1–9)
* Notes toggle button
* Undo button

### T2.2 – Cell Interaction Logic

* Select cell
* Enter number
* Add/remove notes
* Prevent editing fixed cells

### T2.3 – Error Highlighting

* Highlight conflicts in red
* Toggleable via settings

### T2.4 – Hints System

* Reveal one correct cell
* Limit number of hints per puzzle

### T2.5 – Game State Management

* Track current board state
* Track mistakes
* Detect puzzle completion

### T2.6 – Win Condition

* Validate full board
* Show success dialog
* Save completion stats

### T2.7 – Difficulty Selection

* Easy / Medium / Hard / Expert
* Load puzzle based on difficulty

---

## PHASE 3 – Rush Mode (SECOND MODE)

### T3.1 – Rush Mode Screen

* Reuse Classic UI
* Add countdown timer (5 minutes)

### T3.2 – Timer Logic

* Start timer on game start
* Pause/resume support
* End game at 0

### T3.3 – Penalty System

* −10 seconds per wrong entry
* Visual feedback on penalty

### T3.4 – Rush Scoring System

* Base score for completion
* Bonus for remaining time
* Store best scores locally

### T3.5 – Lose Condition

* Timer reaches zero
* Show failure screen

---

## PHASE 4 – Player Progression

### T4.1 – Local Persistence

* Save unfinished games
* Save completed games
* Save best Rush scores

### T4.2 – Player Stats

* Games played
* Games won
* Average solve time

---

## PHASE 5 – Online 1v1 Mode (ADVANCED)

### T5.1 – Backend Selection

* Choose Firebase / Supabase
* Enable auth (anonymous or email)

### T5.2 – Matchmaking Logic

* Create match room
* Assign same Sudoku puzzle to both players

### T5.3 – Real‑Time Sync

* Sync:

  * board state
  * completion status
* Do NOT sync notes

### T5.4 – Win Conditions

* First player to solve wins
* Timeout handling

### T5.5 – Result Screen

* Winner / loser display
* Time comparison

---

## PHASE 6 – Polish & UX

### T6.1 – Animations

* Cell selection animation
* Number entry feedback

### T6.2 – Sound & Haptics

* Toggleable sounds
* Optional vibration

### T6.3 – Settings Screen

* Theme toggle
* Error highlighting toggle
* Sound toggle

---

## RULES FOR CLAUDE (IMPORTANT)

* Do **one task at a time**
* Do **not refactor unrelated files**
* Explain logic briefly after each task
* Ask before introducing new libraries
* Prefer readable, beginner‑friendly Dart code

---

## IMPLEMENTATION ORDER (STRICT)

2. Phase 1
3. Phase 2 (Classic Mode)
4. Phase 3 (Rush Mode)
5. Phase 4
6. Phase 5 (Online 1v1)
7. Phase 6

---

End of task.md
