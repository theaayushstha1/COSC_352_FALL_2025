# Turing Machine Simulator

A comprehensive Turing Machine simulator with CLI and Web interfaces, containerized with Docker. In this project I implement configurable Turing Machines at different complexity levels to verify input strings against formal language constraints.

## Features

- **Multiple Complexity Levels**: Easy, Medium, and Hard Turing Machine configurations
- **Dual Interface**: Both CLI and Web-based interfaces
- **Docker Support**: Fully containerized application
- **State Tracing**: Complete execution trace with visual tape representation
- **Input Validation**: Pass/Fail verification with detailed reasoning
- **Example Inputs**: Built-in valid and invalid examples for testing

## Complexity Levels

### Easy - Equal 0s and 1s
Accepts strings that contain an equal number of 0s and 1s.
- **Valid Examples**: `01`, `0011`, `1100`, `0101`
- **Invalid Examples**: `0`, `1`, `001`, `111`

### Medium - Binary Palindrome
Accepts binary strings that read the same forwards and backwards.
- **Valid Examples**: `0`, `1`, `11`, `101`, `1001`, `10101`
- **Invalid Examples**: `10`, `110`, `1000`, `10110`

### Hard - Balanced Parentheses
Accepts strings with properly balanced parentheses.
- **Valid Examples**: `()`, `(())`, `()()`, `((()))`
- **Invalid Examples**: `(`, `)`, `)(`, `(()`

## Quick Start

### Prerequisites
- Docker installed on your system
- Git (to clone the repository)

### Project Structure
```
turing-machine/
├── turing_machine.py      # Core Turing Machine implementation
├── cli.py                 # Command-line interface
├── app.py                 # Flask web application
├── templates/
│   └── index.html         # Web interface
├── Dockerfile             # Docker configuration
├── requirements.txt       # Python dependencies
└── README.md             # This file
```

## Installation and Setup

### Step 1: Create Project Directory
```bash
mkdir turing-machine
cd turing-machine
```

### Step 2: Have All these Files

the following files with their respective content (provided):

1. `turing_machine.py` - Core implementation
2. `cli.py` - CLI interface
3. `app.py` - Web application
4. `requirements.txt` - Dependencies
5. `Dockerfile` - Docker configuration
6. Create `templates` directory and add `index.html`

```bash
mkdir templates
```

### Step 3: Build Docker Image
```bash
docker build -t turing-machine .
```

This will:
- Create a Python 3.11 slim container
- Install all dependencies
- Copy application files
- Configure the environment

## Usage

### Option 1: Web Interface (Recommended)

Run the web server:
```bash
docker run -p 5000:5000 turing-machine
```

Access the web interface at: **http://localhost:5000**

The web interface provides:
- Interactive complexity selection
- Visual state trace
- Click-to-use example inputs
- Real-time simulation results
- Beautiful, responsive UI

### Option 2: CLI Interface

#### Basic Usage:
```bash
docker run turing-machine python cli.py --complexity medium --input "101"
```

#### With Verbose Output:
```bash
docker run turing-machine python cli.py --complexity easy --input "0011" --verbose
```

#### Save Trace to JSON:
```bash
docker run -v $(pwd):/output turing-machine python cli.py --complexity hard --input "(())" --trace /output/trace.json
```

#### CLI Arguments:
- `--complexity`: Choose `easy`, `medium`, or `hard`
- `--input`: Input string to verify
- `--verbose`: Print detailed state trace
- `--trace`: Save trace to JSON file

## Example Runs

### Example 1: Binary Palindrome (Medium)
```bash
docker run turing-machine python cli.py --complexity medium --input "101" --verbose
```

**Output:**
```
================================================================================
TURING MACHINE SIMULATOR
================================================================================
Complexity: MEDIUM - Binary Palindrome
Description: Accepts binary strings that are palindromes

Input String: '101'
================================================================================

Running Turing Machine...

================================================================================
RESULTS
================================================================================
Input: '101'
Status: ACCEPTED ✓
Reason: Input accepted
Total Steps: 12
Final State: accept
================================================================================

================================================================================
EVALUATION
================================================================================
✓ PASS - Input was accepted by the Turing Machine
  The input '101' satisfies the language constraints.
  The machine reached the accept state after 12 steps.
================================================================================
```

### Example 2: Equal 0s and 1s (Easy)
```bash
docker run turing-machine python cli.py --complexity easy --input "0011"
```

**Output:**
```
================================================================================
RESULTS
================================================================================
Input: '0011'
Status: ACCEPTED ✓
Reason: Input accepted
Total Steps: 8
Final State: accept
================================================================================
```

### Example 3: Balanced Parentheses (Hard)
```bash
docker run turing-machine python cli.py --complexity hard --input "(()"
```

**Output:**
```
================================================================================
RESULTS
================================================================================
Input: '(()'
Status: REJECTED ✗
Reason: Input rejected - no valid transition or explicit reject
Total Steps: 6
Final State: reject
================================================================================

✗ FAIL - Input was rejected by the Turing Machine
  The input '(()' does NOT satisfy the language constraints.
```

## Testing Different Inputs

### Easy Complexity Tests:
```bash
# Valid inputs
docker run turing-machine python cli.py --complexity easy --input "01"
docker run turing-machine python cli.py --complexity easy --input "0011"
docker run turing-machine python cli.py --complexity easy --input "10"

# Invalid inputs
docker run turing-machine python cli.py --complexity easy --input "0"
docker run turing-machine python cli.py --complexity easy --input "001"
docker run turing-machine python cli.py --complexity easy --input "111"
```

### Medium Complexity Tests:
```bash
# Valid inputs
docker run turing-machine python cli.py --complexity medium --input "1"
docker run turing-machine python cli.py --complexity medium --input "11"
docker run turing-machine python cli.py --complexity medium --input "101"
docker run turing-machine python cli.py --complexity medium --input "1001"

# Invalid inputs
docker run turing-machine python cli.py --complexity medium --input "10"
docker run turing-machine python cli.py --complexity medium --input "110"
docker run turing-machine python cli.py --complexity medium --input "1000"
```

### Hard Complexity Tests:
```bash
# Valid inputs
docker run turing-machine python cli.py --complexity hard --input "()"
docker run turing-machine python cli.py --complexity hard --input "(())"
docker run turing-machine python cli.py --complexity hard --input "()()"

# Invalid inputs
docker run turing-machine python cli.py --complexity hard --input "("
docker run turing-machine python cli.py --complexity hard --input ")("
docker run turing-machine python cli.py --complexity hard --input "(()"
```

## Troubleshooting

### Port Already in Use
If port 5000 is already in use:
```bash
docker run -p 8080:5000 turing-machine
# Access at http://localhost:8080
```

### Permission Issues (Linux/Mac)
```bash
sudo docker run -p 5000:5000 turing-machine
```

### View Container Logs
```bash
docker ps  # Get container ID
docker logs <container_id>
```

### Rebuild Image After Changes
```bash
docker build --no-cache -t turing-machine .
```

## Output Files

### JSON Trace Format
When using `--trace` option, the output JSON contains:
```json
{
  "input": "101",
  "complexity": "medium",
  "accepted": true,
  "reason": "Input accepted",
  "steps": 12,
  "trace": [
    {
      "step": 0,
      "state": "q0",
      "head_position": 0,
      "tape": "101",
      "symbol_read": "1"
    },
    ...
  ]
}
```

## Educational Value to me

This project demonstrates:
- Formal language theory
- Turing Machine state transitions
- Computational complexity
- Algorithm verification
- Docker containerization
- Full-stack development (CLI + Web)


### Implementation Features
- Maximum 10,000 steps to prevent infinite loops
- Dynamic tape expansion
- Complete state trace recording
- Visual tape representation with head position
- Comprehensive error handling

## Assignment Requirements Checklist

Program simulates a Turing Machine  
Delivered and runs in Docker container  
Both CLI and Web-based interfaces  
Configurable complexity levels  
Takes inputs and verifies pass/fail  
Prints state trace  
Shows how pass/fail was evaluated  
Detailed run instructions in README  
Example inputs and outputs provided  
Documents AI usage (Claude assisted in development)  

## AI Usage Documentation

This project was developed with assistance from Open wich helped with:
- Documentation and examples
- Testing scenarios and validation

  
**Turing Machine Simulator v1.0**
