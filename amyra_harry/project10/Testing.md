# Testing Documentation

## Test Plan

This document outlines the test cases used to verify the Turing Machine implementation.

## Test Categories

### 1. Basic Acceptance Tests (Should PASS)

| Input | 0s | 1s | Expected | Reasoning |
|-------|----|----|----------|-----------|
| `01` | 1 | 1 | PASS | Equal counts |
| `10` | 1 | 1 | PASS | Equal counts |
| `0011` | 2 | 2 | PASS | Equal counts |
| `1100` | 2 | 2 | PASS | Equal counts |
| `0110` | 2 | 2 | PASS | Equal counts |
| `101010` | 3 | 3 | PASS | Equal counts |

### 2. Basic Rejection Tests (Should FAIL)

| Input | 0s | 1s | Expected | Reasoning |
|-------|----|----|----------|-----------|
| `0` | 1 | 0 | FAIL | Unequal (more 0s) |
| `1` | 0 | 1 | FAIL | Unequal (more 1s) |
| `00` | 2 | 0 | FAIL | Only zeros |
| `11` | 0 | 2 | FAIL | Only ones |
| `000` | 3 | 0 | FAIL | Only zeros |
| `111` | 0 | 3 | FAIL | Only ones |
| `001` | 2 | 1 | FAIL | Unequal (more 0s) |
| `011` | 1 | 2 | FAIL | Unequal (more 1s) |

### 3. Edge Cases

| Input | Expected | Reasoning |
|-------|----------|-----------|
| (empty) | ERROR | Invalid input |
| `abc` | ERROR | Non-binary characters |
| `0 1` | ERROR | Contains space |
| `2` | ERROR | Not binary |

### 4. Longer Strings

| Input | 0s | 1s | Expected |
|-------|----|----|----------|
| `00110011` | 4 | 4 | PASS |
| `10101010` | 4 | 4 | PASS |
| `00011101` | 4 | 4 | PASS |
| `000111` | 3 | 3 | PASS |
| `0001111` | 3 | 4 | FAIL |

## Running Tests

### Manual Testing
```bash
# Build the image
docker build -t turingmachine .

# Run with specific input
echo "01" | docker run -i turingmachine
```

### Automated Testing (using test script)
```bash
# Make script executable
chmod +x test_turing.sh

# Run all tests
./test_turing.sh
```

## Expected Output Format

Every run should show:
1. Program header
2. Algorithm description
3. Execution trace with:
   - Step number
   - Current state
   - Tape contents
   - Head position
   - Action taken
4. Final result (PASS/FAIL)

## Sample Complete Output

### Test: "01" (Should PASS)

```
================================================================================
TURING MACHINE SIMULATOR
================================================================================

This Turing Machine checks if a binary string has equal numbers of 0s and 1s
Examples: '01' -> PASS, '0011' -> PASS, '010' -> FAIL, '111' -> FAIL

Algorithm:
  1. Mark pairs of 0s and 1s with 'X'
  2. If all symbols are marked and tape ends -> ACCEPT
  3. If unpaired symbols remain -> REJECT
================================================================================

Enter a binary string (or 'quit' to exit):
> 01

Processing input: '01'

================================================================================
TURING MACHINE EXECUTION TRACE
================================================================================

Step 0: State = start
  Tape: 01_
  Head: ^
  Action: Initial configuration

Step 1: State = start
  Tape: 01_
  Head:  ^
  Action: Read '0', wrote '0', moved R

Step 2: State = start
  Tape: 01_
  Head:   ^
  Action: Read '1', wrote '1', moved R

Step 3: State = find_zero
  Tape: 01_
  Head:  ^
  Action: Read '_', wrote '_', moved L

Step 4: State = find_one
  Tape: 0X_
  Head: ^
  Action: Read '1', wrote 'X', moved L

Step 5: State = start
  Tape: XX_
  Head:  ^
  Action: Read 'X', wrote 'X', moved R

[Additional steps omitted for brevity]

RESULT:
✓ PASS - Input '01' is ACCEPTED
  The string has equal numbers of 0s and 1s
================================================================================
```

## Verification Checklist

For each test, verify:
- [ ] Correct initial configuration shown
- [ ] Each step shows state, tape, head position
- [ ] Transitions follow the defined rules
- [ ] Final state is correct (accept/reject)
- [ ] Result message is clear
- [ ] Trace is complete (no missing steps)

## Known Limitations

1. **Max Steps**: Limited to 1000 steps to prevent infinite loops
2. **Input Validation**: Only checks for binary characters, not all edge cases
3. **Performance**: O(n²) algorithm, slow for very long strings (1000+ chars)

## Performance Tests

| Input Length | Expected Steps | Actual Steps | Time |
|--------------|----------------|--------------|------|
| 2 | ~10 | TBD | <0.1s |
| 4 | ~30 | TBD | <0.1s |
| 6 | ~60 | TBD | <0.1s |
| 10 | ~150 | TBD | <0.5s |

## Debugging Failed Tests

If a test fails unexpectedly:

1. **Check the trace**: Look at each step
2. **Verify transitions**: Ensure they match the specification
3. **Check head movement**: L/R directions correct?
4. **State names**: Are they exactly right?
5. **Symbols**: 'X' vs 'x', '_' vs space?

## Regression Testing

After any code changes, run:
```bash
# Quick smoke test
echo "01" | docker run -i turingMachine

# Full test suite
./test_turing.sh
```

## Test Coverage

Current coverage:
- ✓ Basic functionality (PASS/FAIL)
- ✓ Trace generation
- ✓ State transitions
- ✓ Head movement
- ✓ Symbol marking
- ✓ Input validation
- ✓ Edge cases
- ✗ Very long inputs (manual test needed)
- ✗ Performance benchmarks

## Future Testing Enhancements

1. Unit tests for individual methods
2. Automated comparison of trace outputs
3. Performance benchmarking
4. Fuzzing with random inputs
5. Integration tests with different Docker versions