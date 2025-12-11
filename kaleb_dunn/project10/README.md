# Project 10: Turing Machine Simulator (C++)

## Overview
A comprehensive Turing Machine simulator implemented in C++ that demonstrates fundamental concepts of computation theory. The simulator features multiple pre-programmed machines, interactive testing, detailed execution traces, and full Docker containerization.

## Features

### 🎯 Four Pre-Programmed Turing Machines

1. **Binary Palindrome Checker** (Complex)
   - Accepts strings that are palindromes over {0,1}
   - Uses multi-pass marking algorithm
   - States: 6 (q0, q1, q2, q3, q4, q5, accept, reject)
   - Examples: "", "0", "1", "010", "101", "0110"

2. **a^n b^n Recognizer** (Medium)
   - Accepts strings of form a^n b^n where n >= 1
   - Classic context-free language
   - States: 4 (q0, q1, q2, q3, accept, reject)
   - Examples: "ab", "aabb", "aaabbb"

3. **Binary Incrementer** (Simple)
   - Adds 1 to a binary number
   - Handles carry propagation
   - States: 3 (q0, q1, q2, accept)
   - Examples: "0"→"1", "111"→"1000"

4. **Even Number of 1's Checker** (Simple)
   - Accepts strings with even count of 1's
   - Two-state FSM equivalent
   - States: 2 (q_even, q_odd, accept, reject)
   - Examples: "", "00", "11", "0110"

### 📊 Detailed Execution Traces
- Step-by-step state transitions
- Tape visualization with head position
- Symbol read/write operations
- Direction of head movement
- Transition function display

### 🎮 Interactive CLI Interface
- Menu-driven selection
- Custom input testing
- Real-time execution visualization
- Pass/fail evaluation with reasoning

## How to Run

### Using Docker (Recommended)
```bash
# Make script executable
chmod +x run.sh

# Build and run
./run.sh
```

### Manual Docker Commands
```bash
# Build image
docker build -t turing-machine .

# Run interactively
docker run -it --rm turing-machine
```

### Local Compilation (Without Docker)
```bash
# Compile
make

# Run
./turing_machine
```