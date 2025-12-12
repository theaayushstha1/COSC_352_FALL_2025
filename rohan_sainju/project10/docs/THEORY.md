# Turing Machine Theory

## What is a Turing Machine?

A Turing Machine (TM) is a mathematical model of computation that defines an abstract machine capable of implementing any computer algorithm. Invented by Alan Turing in 1936, it forms the foundation of theoretical computer science.

## Formal Definition

A Turing Machine is formally defined as a 7-tuple:

**M = (Q, Σ, Γ, δ, q₀, F, R)**

Where:
- **Q**: Finite set of states
- **Σ**: Input alphabet (symbols that can appear in input)
- **Γ**: Tape alphabet (Σ ⊆ Γ, includes blank symbol)
- **δ**: Transition function: Q × Γ → Q × Γ × {L, R, S}
- **q₀**: Start state (q₀ ∈ Q)
- **F**: Set of accept states (F ⊆ Q)
- **R**: Set of reject states (R ⊆ Q)

## Components

### 1. Tape
- **Infinite** in both directions
- Divided into cells, each containing one symbol
- Initially contains input string, rest is blank

### 2. Head
- Points to one cell on the tape
- Can read and write symbols
- Can move left (L), right (R), or stay (S)

### 3. State Register
- Stores current state
- Starts in q₀
- Computation ends in accept or reject state

### 4. Transition Function (δ)
- Defines machine's behavior
- Given current state and symbol: determines next state, what to write, and where to move
- δ(current_state, current_symbol) = (next_state, write_symbol, direction)

## Operation

1. Machine starts in start state q₀ with head at leftmost input symbol
2. At each step:
   - Read symbol under head
   - Look up transition: δ(current_state, current_symbol)
   - Write new symbol
   - Move head (left, right, or stay)
   - Update state
3. Computation ends when:
   - Reach accept state → **ACCEPT**
   - Reach reject state → **REJECT**
   - No valid transition → **REJECT** (implicit)

## Church-Turing Thesis

**Statement**: Any function that can be computed by an algorithm can be computed by a Turing Machine.

This thesis establishes Turing Machines as a universal model of computation, equivalent in power to:
- Modern computers
- Lambda calculus
- Recursive functions

## Decidability

A language L is **decidable** if there exists a Turing Machine that:
- **Accepts** every string in L
- **Rejects** every string not in L
- **Halts** on all inputs

## This Implementation: Binary Palindrome Checker

### Problem
Determine if a binary string is a palindrome (reads same forwards and backwards).

### Approach
1. Mark leftmost unmarked symbol (remember if 0 or 1)
2. Move right to rightmost unmarked symbol
3. Check if it matches the remembered symbol
4. If match: mark it and repeat from step 1
5. If all symbols matched: **ACCEPT**
6. If mismatch found: **REJECT**

### Example Trace: Input "0110"

| Step | State | Tape | Head | Action |
|------|-------|------|------|--------|
| 0 | q0 | 0110 | 0 | Remember '0', mark as 'X' |
| 1 | q1 | X110 | 1 | Move right to end |
| 2 | q1 | X110 | 2 | Move right to end |
| 3 | q1 | X110 | 3 | Move right to end |
| 4 | q1 | X110 | 4 | Found blank, go back |
| 5 | q4 | X110 | 3 | Check: '0' matches! Mark as 'X' |
| 6 | q6 | X11X | 2 | Move left to start |
| ... | ... | ... | ... | ... |
| n | q_accept | XXXX | - | **ACCEPT** |

### Complexity
- **Time**: O(n²) where n is input length
  - Each iteration processes one symbol from each end
  - Each iteration scans entire remaining string
  - n iterations × O(n) scan = O(n²)

- **Space**: O(n) - tape size proportional to input

## Significance

This implementation demonstrates:
1. **Decidability**: The palindrome problem is decidable
2. **Algorithmic thinking**: Breaking complex problems into simple state transitions
3. **Computational model**: How simple rules create complex behavior
4. **Foundation of CS**: Understanding what computers fundamentally can/cannot do

## Further Reading

- Sipser, Michael. "Introduction to the Theory of Computation" (Chapter 3)
- Hopcroft, Motwani, Ullman. "Introduction to Automata Theory" (Chapter 8)
- Turing, Alan. "On Computable Numbers" (1936)