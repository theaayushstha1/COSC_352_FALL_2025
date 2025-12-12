# Quick Start Guide

## TL;DR - Get Running in 3 Commands

```bash
# 1. Build
docker build -t turing-machine .

# 2. Run
docker run -it turing-machine

# 3. Test with input "01"
# Type: 01
# Press Enter
# See the magic happen!
```

## What You'll See

The program will show you:
1. **Initial state** - where the machine starts
2. **Every step** - what it reads, writes, and where it moves
3. **Final result** - PASS or FAIL with explanation

## Quick Examples

### Example 1: PASS
```
Input: 01
Output: ✓ PASS - equal 0s and 1s
```

### Example 2: FAIL
```
Input: 000
Output: ✗ FAIL - unequal 0s and 1s
```

## Tips
- Only use 0s and 1s
- No spaces or other characters
- Empty input = error
- Type 'quit' to exit

## Understanding the Trace
```
Step 1: State = start
  Tape: 01_
  Head: ^          <- Head points here
  Action: Read '0', wrote '0', moved R
```

- **Tape**: Current content (underscores are blanks)
- **Head**: The ^ shows where the machine is reading
- **Action**: What just happened

## What Makes This Pass?
The machine checks: # of 0s == # of 1s
- "01" → 1 zero, 1 one → PASS ✓
- "0011" → 2 zeros, 2 ones → PASS ✓
- "000" → 3 zeros, 0 ones → FAIL ✗

That's it! You're ready to go.