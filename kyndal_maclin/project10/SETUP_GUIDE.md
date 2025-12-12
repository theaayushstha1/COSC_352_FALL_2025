# Complete Setup Guide - Turing Machine Simulator

Follow these steps exactly to get Turing Machine Simulator running perfectly!

## Prerequisites Check

Before starting, ensure you have:
- [ ] Docker installed and running
- [ ] Terminal/Command Prompt access
- [ ] Text editor (VS Code, Sublime, or any editor)
- [ ] At least 500MB free disk space

### Verify Docker Installation
```bash
docker --version
```
You should see something like: `Docker version 24.x.x`

## Step-by-Step Setup

### Step 1: Create Project Directory the way you like
```bash
# Create main directory
mkdir turing-machine
cd turing-machine

# Create subdirectories
mkdir templates
```

### Step 2: Have All these Required Files

#### File 1: turing_machine.py
a file named `turing_machine.py` 

#### File 2: cli.py
a file named `cli.py` 

#### File 3: app.py
a file named `app.py` 

#### File 4: templates/index.html
a file named `index.html` inside the `templates` folder 

#### File 5: Dockerfile
a file named `Dockerfile` (no extension) 

#### File 6: requirements.txt
a file named `requirements.txt` 

#### File 8: test_all.sh (Optional but recommended)
a file named `test_all.sh` 
```bash
chmod +x test_all.sh  # Make it executable on Linux/Mac
```

### Step 3: Verify the File Structure
Your directory should look like this:
```
turing-machine/
├── turing_machine.py
├── cli.py
├── app.py
├── requirements.txt
├── Dockerfile
├── README.md
├── test_all.sh
└── templates/
    └── index.html
```

Verify with:
```bash
ls -la
ls templates/
```

### Step 4: Build Docker Image
```bash
docker build -t turing-machine .
```

**Expected output:**
```
[+] Building 45.2s (12/12) FINISHED
 => [internal] load build definition from Dockerfile
 => => transferring dockerfile: 485B
 => [internal] load .dockerignore
 ...
 => exporting to image
 => => naming to docker.io/library/turing-machine
```

**If you see errors:**
- Check that all files exist
- Verify Dockerfile has no extension
- Ensure you're in the correct directory

### Step 5: Test the Docker Image
```bash
docker images | findstr turing-machine
```

You should see:
```
turing-machine   latest   abc123def456   2 minutes ago   200MB
```

## Verification Tests

### Test 1: Simple CLI Run
```bash
docker run turing-machine python cli.py --complexity medium --input "101"
```

**Expected:** Should show "ACCEPTED ✓"

### Test 2: Web Interface
```bash
docker run -p 5000:5000 turing-machine
```

Open browser to: http://localhost:5000

**Expected:** Beautiful web interface should load

Press `Ctrl+C` to stop the server

### Test 3: Run All Tests (if you created test_all.sh)
```bash
./test_all.sh  # On Linux/Mac
bash test_all.sh  # On Windows Git Bash
```

## Usage Examples

### Example 1: Test Binary Palindrome
```bash
docker run turing-machine python cli.py --complexity medium --input "1001" --verbose
```

### Example 2: Test with Invalid Input
```bash
docker run turing-machine python cli.py --complexity easy --input "000"
```

### Example 3: Save Trace to File
```bash
# Create output directory
mkdir output

# Run with trace output
docker run -v $(pwd)/output:/output turing-machine python cli.py --complexity hard --input "(())" --trace /output/trace.json

# View the trace
cat output/trace.json
```

### Example 4: Run Web Interface on Different Port
```bash
docker run -p 8080:5000 turing-machine
# Access at http://localhost:8080
```

## Troubleshooting

### Problem: "Cannot connect to Docker daemon"
**Solution:**
```bash
# Start Docker Desktop (Windows/Mac)
# Or start Docker service (Linux)
sudo systemctl start docker
```

### Problem: "Port 5000 already in use"
**Solution:**
```bash
# Use a different port
docker run -p 8080:5000 turing-machine
```

### Problem: Build fails with "requirements.txt not found"
**Solution:**
```bash
# Verify file exists
ls requirements.txt

# Check you're in the right directory
pwd

# Rebuild
docker build -t turing-machine .
```

### Problem: "Permission denied" on Linux/Mac
**Solution:**
```bash
sudo docker build -t turing-machine .
sudo docker run -p 5000:5000 turing-machine
```

### Problem: Changes not reflected after editing files
**Solution:**
```bash
# Rebuild without cache
docker build --no-cache -t turing-machine .
```

## Expected Outputs

### Successful CLI Run:
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

### Successful Web Interface:
- Web page loads at http://localhost:5000
- Can select complexity level
- Can input test strings
- Click examples to auto-fill
- Run simulation shows animated results
- State trace displays step-by-step execution


## Understanding the Code

### Turing Machine Core (`turing_machine.py`)
- **TuringMachine class**: Main implementation
- **Transition function**: Maps (state, symbol) to (new_state, write_symbol, direction)
- **State trace**: Records every step of execution
- **Three complexity levels**: Easy, Medium, Hard

### CLI Interface (`cli.py`)
- Argument parsing with `argparse`
- Formatted output with colors
- JSON trace export
- Verbose mode for detailed output

### Web Interface (`app.py` + `index.html`)
- Flask REST API
- Interactive UI with animations
- Real-time simulation
- Visual tape representation

## Tips for Success

1. **Test incrementally**: Build and test after creating each file
2. **Use examples**: Test with provided valid/invalid examples first
3. **Read error messages**: Docker errors are usually descriptive
4. **Check file paths**: Ensure templates/index.html is in correct location
5. **Verify Docker is running**: Most common issue is Docker not started

## Getting Help

If stuck:
1. Re-read this guide carefully
2. Check the Troubleshooting section
3. Verify all files are created correctly
4. Test with simple examples first
5. Check Docker logs: `docker logs <container_id>`


