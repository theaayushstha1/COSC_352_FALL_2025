# Turing Machine Simulator

A configurable Turing Machine simulator with comprehensive tracing, visualization, and documentation. This project implements a deterministic Turing Machine that can be configured to solve various computational problems.

## 📋 Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Examples](#examples)
- [Documentation](#documentation)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Theory](#theory)

## ✨ Features

- ✅ **Configurable**: Define Turing Machines via JSON configuration
- ✅ **Complete Trace**: Step-by-step execution visualization
- ✅ **Interactive Mode**: Test multiple inputs interactively
- ✅ **Batch Testing**: Run test suites from files
- ✅ **Colored Output**: Beautiful terminal output with syntax highlighting
- ✅ **Docker Support**: Fully containerized for easy deployment
- ✅ **Comprehensive Docs**: Theory, architecture, and usage documentation
- ✅ **Example Machines**: Binary palindrome checker included

## 🚀 Quick Start

### Using Docker (Recommended)
```bash
# Build the Docker image
docker build -t turing-machine .

# Run with a specific input
docker run --rm turing-machine --config examples/palindrome_config.json --input "0110"

# Run in interactive mode
docker run --rm -it turing-machine --config examples/palindrome_config.json --interactive

# Run test suite
docker run --rm turing-machine --config examples/palindrome_config.json --test-file tests/test_cases.txt
```

### Local Installation
```bash
# Install dependencies
pip install -r requirements.txt

# Run with specific input
python -m src.cli --config examples/palindrome_config.json --input "0110"

# Interactive mode
python -m src.cli --config examples/palindrome_config.json --interactive

# Run tests
python -m src.cli --config examples/palindrome_config.json --test-file tests/test_cases.txt
```

## 📦 Installation

### Prerequisites

- Python 3.11 or higher
- Docker (optional, for containerized execution)

### Steps

1. **Clone the repository**:
```bash
   git clone <your-repo-url>
   cd project10
```

2. **Install Python dependencies**:
```bash
   pip install -r requirements.txt
```

3. **Verify installation**:
```bash
   python -m src.cli --help
```

## 💻 Usage

### Command Line Options
```
usage: cli.py [-h] --config CONFIG [--input INPUT] [--interactive] [--test-file TEST_FILE]

Turing Machine Simulator

options:
  -h, --help            show this help message and exit
  --config CONFIG, -c CONFIG
                        Path to Turing Machine configuration JSON file
  --input INPUT, -i INPUT
                        Input string to process
  --interactive, -int   Run in interactive mode
  --test-file TEST_FILE, -t TEST_FILE
                        File containing test cases (one per line)
```

### Running Examples

**Test if "0110" is a palindrome**:
```bash
python -m src.cli --config examples/palindrome_config.json --input "0110"
```

**Interactive mode** (recommended for exploring):
```bash
python -m src.cli --config examples/palindrome_config.json --interactive
```

**Run all test cases**:
```bash
python -m src.cli --config examples/palindrome_config.json --test-file tests/test_cases.txt
```

## ⚙️ Configuration

Turing Machines are defined in JSON configuration files. See `examples/palindrome_config.json` for a complete example.

### Configuration Format
```json
{
  "name": "Machine Name",
  "description": "What it computes",
  "states": ["q0", "q1", "q_accept", "q_reject"],
  "input_alphabet": ["0", "1"],
  "tape_alphabet": ["0", "1", "X", "Y", "_"],
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

### Transition Directions

- `R`: Move head right
- `L`: Move head left
- `S`: Stay (don't move)

## 📚 Examples

### Example 1: Palindrome "0110"

**Input**: `0110`

**Output**:
```
✓ ACCEPTED: Input accepted in state 'q_accept' after 42 steps

Computation Trace:
+------+--------+------+-------+------+----------+----------+
| Step | State  | Read | Write | Move | Head Pos | Tape     |
+======+========+======+=======+======+==========+==========+
|    0 | INIT   | _    | _     | S    |        0 | 0110     |
|    1 | q0     | 0    | X     | R    |        0 | 0110     |
|    2 | q1     | 1    | 1     | R    |        1 | X110     |
| ...  | ...    | ...  | ...   | ...  |      ... | ...      |
+------+--------+------+-------+------+----------+----------+

Decision: ACCEPTED ✓
Reason: The Turing Machine reached an accept state.
```

### Example 2: Non-Palindrome "0111"

**Input**: `0111`

**Output**:
```
✗ REJECTED: Input rejected in state 'q_reject' after 28 steps

Decision: REJECTED ✗
Reason: The Turing Machine reached a reject state or no valid transition was found.
```

## 📖 Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[THEORY.md](docs/THEORY.md)**: Turing Machine theory, formal definition, and how this implementation works
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)**: System design, component details, and design decisions
- **[AI_USAGE.md](docs/AI_USAGE.md)**: Transparent documentation of how AI assisted in development

## 📁 Project Structure
```
project10/
├── Dockerfile                 # Docker configuration
├── README.md                  # This file
├── requirements.txt           # Python dependencies
├── src/                       # Source code
│   ├── __init__.py
│   ├── cli.py                # Command-line interface
│   ├── turing_machine.py     # Core TM implementation
│   ├── tape.py               # Tape abstraction
│   └── transition.py         # Transition function
├── examples/                  # Example TM configurations
│   └── palindrome_config.json
├── tests/                     # Test cases
│   └── test_cases.txt
└── docs/                      # Documentation
    ├── THEORY.md
    ├── ARCHITECTURE.md
    └── AI_USAGE.md
```

## 🧪 Testing

### Running Tests
```bash
# Run all test cases
python -m src.cli --config examples/palindrome_config.json --test-file tests/test_cases.txt

# Docker version
docker run --rm turing-machine --config examples/palindrome_config.json --test-file tests/test_cases.txt
```

### Test Cases Included

- Empty string
- Single characters (0, 1)
- Even-length palindromes (00, 11, 0110, 1001)
- Odd-length palindromes (0, 1, 010, 101)
- Non-palindromes (01, 10, 0111, 1000)
- Long strings

### Expected Results

| Input | Expected | Reason |
|-------|----------|--------|
| (empty) | ACCEPT | Empty string is palindrome |
| 0 | ACCEPT | Single char is palindrome |
| 01 | REJECT | Not same forwards/backwards |
| 0110 | ACCEPT | Reads same both ways |
| 0111 | REJECT | Different forwards/backwards |

## 📐 Theory

This Turing Machine implements a **binary palindrome checker** using a mark-and-check strategy:

1. **Mark** leftmost unmarked symbol (remember if 0 or 1)
2. **Move** right to rightmost unmarked symbol
3. **Check** if it matches the remembered symbol
4. **Repeat** until all symbols processed
5. **Accept** if all matched, **reject** otherwise

**Time Complexity**: O(n²) where n is input length  
**Space Complexity**: O(n) for tape storage

For detailed theory, see [docs/THEORY.md](docs/THEORY.md).

## 🐳 Docker

### Building
```bash
docker build -t turing-machine .
```

### Running
```bash
# Single input
docker run --rm turing-machine --config examples/palindrome_config.json --input "0110"

# Interactive
docker run --rm -it turing-machine --config examples/palindrome_config.json --interactive

# Tests
docker run --rm turing-machine --config examples/palindrome_config.json --test-file tests/test_cases.txt
```

### Docker Features

- ✅ Based on Python 3.11-slim
- ✅ Non-root user for security
- ✅ Minimal image size
- ✅ All dependencies included

## 🎓 Educational Value

This project demonstrates:

- ✅ Theoretical computer science concepts
- ✅ Algorithm design and verification
- ✅ Software architecture and modularity
- ✅ Clean code practices
- ✅ Comprehensive documentation
- ✅ Container orchestration

## 📄 License

MIT License - See LICENSE file for details

## 👤 Author

Rohan - Morgan State University  
Course: COSC 352  
Project: 10 - Turing Machine Simulator

## 🙏 Acknowledgments

- Alan Turing for inventing the Turing Machine
- Morgan State University Computer Science Department