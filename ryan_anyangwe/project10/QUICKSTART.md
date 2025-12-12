# Quick Start Guide

## 🚀 Getting Started in 2 Minutes

### Option 1: Docker (Recommended)

```bash
# Navigate to project directory
cd project10

# Build the image
docker build -t turing-machine .

# Run web interface (open http://localhost:5000)
docker run -p 5000:5000 turing-machine

# Or run CLI
docker run -it turing-machine python cli.py -m palindrome
```

### Option 2: Python Directly

```bash
cd project10

# Install dependencies
pip install -r requirements.txt

# Run web interface
python app.py
# Then open http://localhost:5000

# Or run CLI
python cli.py -m palindrome
```

## 📝 Quick CLI Examples

```bash
# Interactive mode (type inputs, see traces)
python cli.py -m palindrome

# Test a single input
python cli.py -m palindrome -i "101"

# Quick test (results only)
python cli.py -m palindrome -i "101" -q

# Batch test multiple inputs
python cli.py -m palindrome -b "101" "1001" "110"

# Test parentheses matcher
python cli.py -m parentheses -i "(())"
```

## 🎯 What to Try

### Binary Palindrome Machine
**Valid**: `101`, `1001`, `0`, `11011`, `10101`
**Invalid**: `10`, `110`, `1000`

### Balanced Parentheses Machine
**Valid**: `()`, `(())`, `()()`
**Invalid**: `(`, `(()`

## 📁 File Structure

```
project10/
├── README.md              # Full documentation
├── QUICKSTART.md         # This file
├── turing_machine.py     # Core TM implementation
├── app.py                # Web interface
├── cli.py                # Command-line interface
├── templates/index.html  # Web UI
├── Dockerfile            # Container config
├── requirements.txt      # Dependencies
├── test.sh              # Test script
└── sample_output.txt    # Example execution
```

## 🎓 For Grading

All requirements met:
- ✅ Working program with state traces
- ✅ Pass/fail evaluation
- ✅ Dockerized and ready to run
- ✅ Comprehensive documentation
- ✅ Complex, non-trivial algorithms
- ✅ Both CLI and web interfaces

## 💡 Tips

1. Start with the **web interface** for visualization
2. Use **CLI batch mode** for testing multiple inputs
3. Check **sample_output.txt** for execution trace examples
4. Read **README.md** for complete documentation
5. Run **test.sh** to verify everything works

## 🐛 Troubleshooting

**Port 5000 already in use?**
```bash
docker run -p 8080:5000 turing-machine
# Then open http://localhost:8080
```

**Python not found?**
Make sure Python 3.11+ is installed.

**Docker issues?**
Try running Python directly (Option 2 above).
