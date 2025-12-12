# Architecture Documentation

## System Overview

This project implements a configurable Turing Machine simulator with a modular architecture designed for extensibility, testability, and educational clarity.

## Design Principles

1. **Separation of Concerns**: Each component has a single, well-defined responsibility
2. **Configuration-Driven**: Machine behavior defined in JSON, not hardcoded
3. **Extensibility**: Easy to add new TM configurations
4. **Observability**: Complete trace of computation for debugging
5. **User-Friendly**: Clear CLI with colored output and formatted tables

## Architecture Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                         CLI Layer                            │
│  (User Interface, Input Handling, Output Formatting)        │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    Turing Machine Core                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │    Tape      │  │  Transition  │  │    State     │     │
│  │   Manager    │  │   Function   │  │   Manager    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                  Configuration Layer                         │
│              (JSON Configuration Files)                      │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Tape (`src/tape.py`)

**Responsibility**: Manage infinite tape and head operations

**Key Features**:
- Dictionary-based storage for infinite extension
- Automatic blank symbol handling
- Boundary tracking for efficient display
- Context-aware tape rendering

**Design Decisions**:
- **Dict vs List**: Using dictionary allows true "infinite" tape without pre-allocation
- **Lazy Initialization**: Only allocate cells when written
- **Bounds Tracking**: Optimize display by tracking min/max written positions
```python
# Efficient O(1) access regardless of position
tape[-1000]  # Works instantly
tape[1000]   # Works instantly
```

### 2. Transition Function (`src/transition.py`)

**Responsibility**: Encode and execute state transition rules

**Key Features**:
- Clean API for adding transitions
- Fast O(1) lookup using (state, symbol) tuples as keys
- JSON configuration loading
- Human-readable string representation

**Design Decisions**:
- **Tuple Keys**: `(state, symbol)` as dict key for O(1) lookup
- **No Default Transitions**: Explicit reject on missing transition
- **Immutable After Load**: Transitions set once, never modified

### 3. Turing Machine (`src/turing_machine.py`)

**Responsibility**: Orchestrate computation and manage execution

**Key Features**:
- Complete execution trace
- Step-by-step computation
- Infinite loop detection (max steps)
- Input validation
- Accept/reject determination

**Design Decisions**:
- **Stateful Execution**: Machine maintains current state during run
- **Reset Between Runs**: Clean slate for each input
- **Trace Everything**: Record every step for debugging and display
- **Fail-Safe**: Max steps prevents infinite loops

**Execution Flow**:
```
1. Validate input ∈ Σ*
2. Initialize tape with input
3. Set state = q₀, head = 0
4. Loop:
   a. Read current symbol
   b. Look up transition
   c. Write symbol
   d. Move head
   e. Update state
   f. Record step
   g. Check termination
5. Return (accepted, trace)
```

### 4. CLI (`src/cli.py`)

**Responsibility**: User interface and output formatting

**Key Features**:
- Colored terminal output (via colorama)
- Formatted tables (via tabulate)
- Interactive mode
- Batch testing from file
- Detailed evaluation explanations

**Design Decisions**:
- **Colorama**: Cross-platform color support (Windows/Unix)
- **Tabulate**: Professional table formatting
- **Progressive Display**: Show trace during long computations
- **Error Handling**: Graceful failures with helpful messages

## Configuration Format

JSON configuration defines TM behavior:
```json
{
  "name": "Machine Name",
  "description": "What it does",
  "states": ["q0", "q1", "q_accept", "q_reject"],
  "input_alphabet": ["0", "1"],
  "tape_alphabet": ["0", "1", "X", "_"],
  "blank_symbol": "_",
  "start_state": "q0",
  "accept_states": ["q_accept"],
  "reject_states": ["q_reject"],
  "transitions": [
    {
      "current_state": "q0",
      "read_symbol": "0",
      "next_state": "q1",
      "write_symbol": "X",
      "direction": "R",
      "comment": "Optional explanation"
    }
  ]
}
```

## Data Flow
```
User Input
    │
    ▼
[CLI validates & parses]
    │
    ▼
[Load TM from config]
    │
    ▼
[Initialize tape with input]
    │
    ▼
[Execute step-by-step] ──────┐
    │                         │
    ▼                         │
[Record each step]            │
    │                         │
    ▼                         │
[Check termination] ──────────┘
    │
    ▼
[Format & display trace]
    │
    ▼
[Show accept/reject decision]
    │
    ▼
[Explain evaluation]
```

## Testing Strategy

### Unit Testing (Potential)
- `test_tape.py`: Tape read/write, infinite extension
- `test_transition.py`: Transition lookup, missing transitions
- `test_tm.py`: Execution, acceptance, rejection

### Integration Testing
- End-to-end runs with known inputs
- Test cases file: `tests/test_cases.txt`
- Verify trace correctness

### Edge Cases Handled
- Empty input
- Single character
- All same character
- Very long inputs
- Invalid input alphabet
- Missing transitions
- Infinite loops (max steps)

## Performance Characteristics

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| Tape read/write | O(1) | Dict access |
| Transition lookup | O(1) | Dict access |
| Single step | O(1) | Constant operations |
| Full execution | O(s) | s = number of steps |
| Palindrome check | O(n²) | n = input length |

## Extensibility

### Adding New Machines
1. Create new JSON config in `examples/`
2. Define states, alphabets, transitions
3. No code changes needed!

### Supported Features
- Any number of states
- Any tape alphabet
- Deterministic transitions
- Single tape (not multi-tape)
- Stay (S) direction supported

### Limitations
- Deterministic only (no non-deterministic TMs)
- Single tape (no multi-tape simulation)
- No probabilistic transitions

## Security Considerations

### Docker
- Non-root user (`tmuser`)
- Minimal base image
- No network access needed
- Read-only code directory

### Input Validation
- Alphabet checking
- Max steps limit
- JSON schema validation
- File path sanitization

## Future Enhancements

1. **Web Interface**: Flask/FastAPI web UI
2. **Visualization**: Animated step-by-step display
3. **Multi-tape**: Simulate multi-tape TMs
4. **Non-deterministic**: NTM simulation with backtracking
5. **Performance**: Compile to native code
6. **Export**: Generate LaTeX diagrams

## Code Quality

- **Type Hints**: All functions typed
- **Docstrings**: Comprehensive documentation
- **Comments**: Explain complex logic
- **Style**: PEP 8 compliant
- **Modularity**: Clear separation of concerns