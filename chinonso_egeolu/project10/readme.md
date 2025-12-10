# Project 10: Turing Machine Simulator

Interactive Turing Machine simulator with **both CLI and Web UI** implementations in JavaScript/Node.js.

## Features

🎯 **Dual Interface**
- Interactive command-line interface
- Beautiful web-based visual interface

🤖 **Three Pre-Built Machines**
- Binary Palindrome Checker
- Balanced Parentheses Checker
- a^n b^n Language Recognizer

📊 **Complete State Tracing**
- Step-by-step execution visualization
- Tape contents at each step
- State transitions and head movements

## Quick Start

### CLI Mode (Docker)

```bash
# Build
docker build -t turing-machine .

# Run interactive CLI
docker run -it --rm turing-machine

# Run automated tests
docker run --rm turing-machine node turing-machine.js --test
```

### Web UI Mode (Docker)

```bash
# Build
docker build -t turing-machine .

# Run web server
docker run -p 3000:3000 turing-machine node server.js

# Open browser
open http://localhost:3000
```

### Local Development

```bash
# Install dependencies
npm install

# Run CLI
node turing-machine.js

# Run web UI
npm run web
# Then visit http://localhost:3000

# Run tests
npm test
```

## Available Machines

### 1. Binary Palindrome Checker

Checks if binary strings are palindromes.

**Examples:**
- `101` → ✓ (reads same forwards/backwards)
- `1001` → ✓
- `110` → ✗

**Algorithm:** Mark and compare symbols from both ends.

### 2. Balanced Parentheses Checker

Verifies matching parentheses.

**Examples:**
- `()` → ✓
- `(())` → ✓
- `(()` → ✗

**Algorithm:** Match each `(` with corresponding `)`.

### 3. a^n b^n Language

Accepts n a's followed by n b's.

**Examples:**
- `ab` → ✓
- `aabb` → ✓
- `aab` → ✗

**Algorithm:** Mark equal numbers of a's and b's.

## Example CLI Session

```
TURING MACHINE SIMULATOR
======================================================================

Available Machines:
  1. Binary Palindrome Checker (e.g., "1001", "0110")
  2. Balanced Parentheses Checker (e.g., "(())", "()()")
  3. a^n b^n Language (e.g., "aabb", "aaabbb")
  4. Exit

Select a machine (1-4): 1

Selected: Binary Palindrome Checker
======================================================================

Enter input string (or "back" to return): 1001

======================================================================
Running Turing Machine on input: '1001'
======================================================================

Step   State      Head   Symbol   Tape
----------------------------------------------------------------------
0      q0         0      1        [1]001
1      q2         1      0        X[0]01
2      q2         2      0        X0[0]1
...

======================================================================
✓ ACCEPTED - Input '1001' is in the language
Total steps: 25
Final state: accept
======================================================================
```

## Web UI Features

- **Machine Selection** - Dropdown to choose machine
- **Live Examples** - Click-to-run example inputs
- **Visual Results** - Color-coded accept/reject
- **Complete Trace** - Scrollable step-by-step execution
- **Statistics** - Step count and final state
- **Responsive Design** - Works on desktop and mobile

## Project Structure

```
project10/
├── turing-machine.js    # Core simulator + CLI
├── server.js           # Express web server
├── package.json        # Dependencies
├── Dockerfile          # Container config
├── public/
│   └── index.html     # Web UI
└── README.md          # This file
```

## Implementation Details

### Turing Machine Components

**Tape:** Infinite in both directions, implemented as JavaScript Map (sparse)

**Head:** Integer position on tape

**State:** String representing current state

**Transitions:** Object mapping `state,symbol` → `[newState, newSymbol, direction]`

### Time Complexity

All three machines: **O(n²)**
- Each symbol may require full tape scan
- n symbols × n positions = O(n²)

### Space Complexity

**O(n)** - Sparse tape stores only non-blank cells

## Generative AI Usage

### Claude AI Assistance

### Learning Outcomes:

- Understanding of Turing Machine mechanics
- JavaScript async/await patterns
- Express.js web server setup
- Responsive CSS design
- State machine implementation

## Technologies Used

- **Node.js 18** - JavaScript runtime
- **Express.js** - Web server framework
- **Vanilla JS** - No frontend frameworks (lightweight)
- **CSS3** - Modern styling with gradients
- **Docker** - Containerization

## Author

Chinonso Egeolu

## References

- Turing, A.M. (1936). "On Computable Numbers"
- Sipser, M. "Introduction to the Theory of Computation"