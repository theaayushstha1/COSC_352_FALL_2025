# Project 10: "Ping-Pong" Palindrome Turing Machine

This simulation implements a Turing Machine to solve the Palindrome problem ($L = \{w w^R\}$).

## The Ping-Pong Logic

Unlike a standard TM that constantly rewinds to the start, this machine processes the string from **both ends**, shrinking the search space with every step.

1.  **Left $\to$ Right Scan:**
    * Read leftmost bit. Mark **X**.
    * Travel Right (skipping 0/1).
    * Find rightmost bit (before Y or Blank).
    * Compare. If match, Mark **Y**.

2.  **Right $\to$ Left Scan:**
    * Immediately read the *next* available bit on the Right (neighbor of the Y we just marked).
    * Mark **Y**.
    * Travel Left (skipping 0/1).
    * Find leftmost bit (after X).
    * Compare. If match, Mark **X**.

3.  **Completion:**
    * If markers meet (X meets Y) or only 1 char remains, the string is a Palindrome.
    * The machine wipes the tape and writes **1** at Index 0.
    * If a mismatch occurs at any step, it wipes the tape and writes **0** at Index 0.

## Usage

```bash
# Build
docker build -t tm-pingpong .

# Run Pass Case (Even)
docker run --rm tm-pingpong 1001

# Run Pass Case (Odd)
docker run --rm tm-pingpong 10101

# Run Fail Case
docker run --rm tm-pingpong 1011