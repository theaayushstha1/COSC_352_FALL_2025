# Turing Machine Simulator

**Author:** Kayla Trogdon  
**Course:** COSC 352 - Functional Programming  
**Project:** Project 10 - Turing Machine Simulator  

An interactive web-based Turing Machine simulator that demonstrates fundamental concepts of computation theory through three working Turing Machines with complete state trace visualization.

---

## 🚀 Quick Start

### Prerequisites
- **Docker** installed on your machine ([Get Docker](https://docs.docker.com/get-docker/))
- **OR** Python 3.11+ and pip

---

### Option 1: Using Docker (Recommended)
```bash
# 1. Clone the repository
git clone https://github.com/yourusername/project10.git
cd project10

# 2. Make the run script executable
chmod +x run.sh

# 3. Run the application
./run.sh
```

The script will automatically:
- Build the Docker image
- Start the container
- Launch the web interface

**Open your browser to:** http://localhost:5000

Press `Ctrl+C` to stop the simulator.

### Using the Simulator

1. **Select a Turing Machine** by clicking one of the three cards
2. **Enter an input string** (or click a quick test button)
   - Binary Palindrome: try `101` or `1001`
   - Binary Adder: try `111` or `1111`
   - Balanced Parens: try `()` or `(())`
3. **Click "Run Simulation"**
4. **View results:**
   - Green badge = Accepted ✓
   - Red badge = Rejected ✗
   - State trace shows each step of computation
```

---

## 🤖 Implemented Turing Machines

### 1. Binary Palindrome Checker

**Purpose:** Determines if a binary string reads the same forwards and backwards.

**Algorithm:**
1. Mark the leftmost unmatched symbol with 'X'
2. Scan to the rightmost unmatched symbol
3. Check if symbols match
4. If match, mark with 'X' and repeat
5. Accept if all symbols matched; reject otherwise

**Examples:**
- `101` → **ACCEPT** ✓ (reads same both ways)
- `1001` → **ACCEPT** ✓
- `110` → **REJECT** ✗ (not a palindrome)

**Alphabet:** `{0, 1}`  
**States:** 8 states  
**Complexity:** O(n²)

---

### 2. Binary Number Adder

**Purpose:** Adds 1 to a binary number, demonstrating carry propagation.

**Algorithm:**
1. Move to rightmost digit
2. If digit is 0: change to 1, accept
3. If digit is 1: change to 0, move left (carry)
4. Repeat until carry resolves or reach beginning
5. If carry at beginning, prepend 1

**Examples:**
- `111` (7) → `1000` (8) ✓
- `101` (5) → `110` (6) ✓
- `0` (0) → `1` (1) ✓

**Alphabet:** `{0, 1}`  
**States:** 5 states  
**Complexity:** O(n)

---

### 3. Balanced Parentheses Checker

**Purpose:** Verifies proper nesting and balance of parentheses.

**Algorithm:**
1. Find first unmarked '('
2. Mark it with 'X'
3. Scan for matching ')'
4. Mark it with 'Y'
5. Return to start and repeat
6. Accept if all matched; reject if unbalanced

**Examples:**
- `()` → **ACCEPT** ✓
- `(())` → **ACCEPT** ✓
- `(()` → **REJECT** ✗ (unmatched opening)
- `())` → **REJECT** ✗ (extra closing)

**Alphabet:** `{(, )}`  
**States:** 5 states  
**Complexity:** O(n²)

---

## 🎯 Features

### Interactive Web Interface
- **Beautiful UI:** Clean, modern design with gradient backgrounds
- **Visual State Traces:** See every step of the computation
- **Tape Head Highlighting:** Yellow brackets `[symbol]` show current position
- **Real-time Results:** Instant feedback on accept/reject
- **Multiple TMs:** Switch between different machines seamlessly

---

## 📁 Project Structure
```
project10/
├── app/
│   ├── machines/
│   │   ├── palindrome.py           # Binary palindrome checker TM
│   │   ├── binary_adder.py         # Binary adder TM
│   │   └── balanced_parens.py      # Parentheses checker TM
│   ├── static/
│   │   └── style.css               # Stylesheet
│   ├── templates/
│   │   └── index.html              # Web interface
│   ├── app.py                      # Flask server
│   └── turing_machine.py           # Core TM engine
├── docs/
│   ├── my_approach.md              # Development approach
├── Dockerfile                       # Docker container setup
├── requirements.txt                # Python dependencies
├── run.sh                          # Quick start script
├── .gitignore                      # Git exclusions
└── README.md                       # This file
```

---

## 💻 Development Approach

### 1. Core Engine First (Test-Driven Development)
I started by building the core Turing Machine engine (`turing_machine.py`) with a simple, working implementation. Each component was tested independently before integration:

- **TM Engine:** Built the tape simulation, state management, and transition logic
- **Testing:** Created test cases for each TM before implementing algorithms
- **Iterative Development:** Tested each machine individually before adding to the web interface

### 2. Algorithm Design
For each Turing Machine, I:
- Researched standard TM algorithms for the problem
- Designed state transition diagrams on paper
- Implemented transitions in Python dictionaries
- Tested with multiple inputs (palindromes, edge cases, etc.)
- Verified all test cases passed before moving forward

### 3. Web Interface Development
Built the Flask application in stages:
- **Backend:** REST API for TM simulation
- **Frontend:** HTML interface with machine selection
- **Styling:** CSS for professional appearance
- **Integration:** Connected frontend to backend via fetch API
- **Testing:** Verified each TM works through the web interface

### 4. Docker Containerization
Final step was making the application portable:
- Created Dockerfile with Python 3.11 base image
- Tested build process locally
- Added run.sh script for easy deployment
- Verified container runs on port 5000

### 5. Documentation
Comprehensive documentation written throughout development:
- Inline code comments explaining algorithms
- README with usage instructions
- Technical documentation in docs/ folder

---

## 🤖 Use of Generative AI

This project was developed with assistance from **Claude (Anthropic)**. Here's how AI was leveraged:

### What AI Helped With:
1. **Algorithm Design:** Discussed Turing Machine transition logic and state design for each algorithm
2. **Code Structure:** Guidance on organizing the Flask application and TM engine architecture  
3. **Debugging:** Assistance fixing bugs in state transitions (e.g., palindrome odd-length edge case)
4. **Web Interface:** HTML/CSS/JavaScript code for the frontend visualization
5. **Docker Setup:** Dockerfile and docker-compose.yml configuration
6. **Documentation:** Structure and content for README and technical docs

### My Contributions:
- **Problem-solving:** Analyzed requirements and determined which TMs to implement
- **Testing:** Created comprehensive test cases and validated all results
- **Integration:** Connected all components (TM engine, Flask, frontend, Docker)
- **Customization:** Adapted AI suggestions to fit project requirements
- **Debugging:** Identified and fixed issues through testing and iteration

### Development Process:
- Used AI as a **collaborative coding partner**, not an automatic code generator
- Reviewed and understood all AI-provided code before implementation
- Tested each component thoroughly to ensure correctness
- Made modifications based on testing results

**Key Takeaway:** AI accelerated development by providing boilerplate code and suggestions, but understanding the algorithms, debugging, testing, and integration were all done independently.

---

---

## 🛠️ Technical Implementation

### Core Engine (`turing_machine.py`)

The TM simulator implements:
- **Tape:** Dynamic list that expands as needed
- **Head Position:** Integer index tracking current cell
- **State Management:** Current state tracking and transitions
- **Transition Function:** Dictionary-based state transitions
- **Trace Recording:** Complete execution history

**Key Methods:**
- `initialize_tape()` - Setup tape with input
- `step()` - Execute single transition
- `run()` - Complete simulation with max_steps limit
- `_record_trace()` - Track each configuration

### Web Interface (`app.py`)

Flask application providing:
- **REST API:** `/simulate` endpoint for TM execution
- **Health Check:** `/health` for status monitoring
- **Machine Registry:** Dynamic TM loading
- **Error Handling:** Graceful failure management

### Frontend (`index.html` + `style.css`)

Modern web interface featuring:
- **Responsive Design:** Works on all screen sizes
- **Interactive Cards:** Click to select machines
- **Live Results:** Real-time trace visualization
- **Color Coding:** Visual feedback for accept/reject
- **Quick Tests:** One-click example inputs

---

## 📊 Performance

| Machine | Average Steps | Complexity | Max Input Tested |
|---------|--------------|------------|------------------|
| Palindrome | O(n²) | Quadratic | 12 bits |
| Binary Adder | O(n) | Linear | 16 bits |
| Balanced Parens | O(n²) | Quadratic | 8 pairs |

All simulations complete in under 1 second for typical inputs.

---

**Project Status:** ✅ Complete and Fully Functional