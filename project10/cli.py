#!/usr/bin/env python3
"""
Command-Line Interface for Turing Machine Simulator
"""

import sys
import argparse
from turing_machine import (
    create_binary_palindrome_tm,
    create_balanced_parentheses_tm
)

def print_banner():
    """Print a nice banner"""
    print("=" * 80)
    print(" " * 20 + "TURING MACHINE SIMULATOR")
    print(" " * 15 + "Command-Line Interface v1.0")
    print("=" * 80)
    print()

def print_machine_info(machine_name, tm_creator):
    """Print information about a Turing Machine"""
    machines_info = {
        'palindrome': {
            'name': 'Binary Palindrome Recognizer',
            'description': 'Recognizes binary strings that read the same forwards and backwards',
            'alphabet': '{0, 1}',
            'examples_valid': ['0', '1', '101', '1001', '11011', '10101'],
            'examples_invalid': ['10', '110', '1000', '10110']
        },
        'parentheses': {
            'name': 'Balanced Parentheses Checker',
            'description': 'Recognizes strings with properly balanced parentheses',
            'alphabet': '{(, )}',
            'examples_valid': ['()', '(())', '()()', '((()))'],
            'examples_invalid': ['(', ')', '(()', '())', '(()))']
        }
    }
    
    info = machines_info.get(machine_name, {})
    
    print(f"Machine: {info.get('name', 'Unknown')}")
    print(f"Description: {info.get('description', 'N/A')}")
    print(f"Alphabet: {info.get('alphabet', 'N/A')}")
    print()
    print("Valid Examples:")
    for ex in info.get('examples_valid', []):
        print(f"  ✓ '{ex}'")
    print()
    print("Invalid Examples:")
    for ex in info.get('examples_invalid', []):
        print(f"  ✗ '{ex}'")
    print()

def interactive_mode(machine_name, tm_creator):
    """Run in interactive mode"""
    print_banner()
    print_machine_info(machine_name, tm_creator)
    print("=" * 80)
    print("Interactive Mode - Enter strings to test (Ctrl+C or 'quit' to exit)")
    print("=" * 80)
    print()
    
    while True:
        try:
            input_str = input("Enter input string: ").strip()
            
            if input_str.lower() in ['quit', 'exit', 'q']:
                print("\nGoodbye!")
                break
            
            # Create fresh TM for each run
            tm = tm_creator()
            
            # Run the machine
            accepted, trace = tm.run(input_str)
            
            print()
            print(tm.format_trace())
            print()
            
        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break
        except Exception as e:
            print(f"\nError: {e}\n")

def batch_mode(machine_name, tm_creator, test_inputs):
    """Run in batch mode with multiple inputs"""
    print_banner()
    print_machine_info(machine_name, tm_creator)
    print("=" * 80)
    print(f"Batch Mode - Testing {len(test_inputs)} inputs")
    print("=" * 80)
    print()
    
    results = []
    
    for input_str in test_inputs:
        tm = tm_creator()
        accepted, trace = tm.run(input_str)
        
        result_symbol = "✓ ACCEPTED" if accepted else "✗ REJECTED"
        results.append((input_str, accepted, len(trace)))
        
        print(f"Input: '{input_str:15s}' | {result_symbol} | Steps: {len(trace)}")
    
    print()
    print("=" * 80)
    print(f"Summary: {sum(1 for _, a, _ in results if a)}/{len(results)} accepted")
    print("=" * 80)

def single_run(machine_name, tm_creator, input_str, verbose=True):
    """Run a single input and show results"""
    tm = tm_creator()
    accepted, trace = tm.run(input_str)
    
    if verbose:
        print_banner()
        print_machine_info(machine_name, tm_creator)
        print(tm.format_trace())
    else:
        result = "ACCEPTED" if accepted else "REJECTED"
        print(f"{result} | Steps: {len(trace)}")
    
    return accepted

def main():
    parser = argparse.ArgumentParser(
        description='Turing Machine Simulator - Explore computational theory',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Interactive mode (default)
  python cli.py -m palindrome
  
  # Test a single input
  python cli.py -m palindrome -i "101"
  
  # Batch mode with multiple inputs
  python cli.py -m palindrome -b "101" "1001" "110" "0"
  
  # Quick test (minimal output)
  python cli.py -m palindrome -i "101" -q

Available Machines:
  palindrome   - Binary palindrome recognizer
  parentheses  - Balanced parentheses checker
        """
    )
    
    parser.add_argument('-m', '--machine', 
                       choices=['palindrome', 'parentheses'],
                       default='palindrome',
                       help='Select Turing Machine to use')
    
    parser.add_argument('-i', '--input',
                       type=str,
                       help='Single input string to test')
    
    parser.add_argument('-b', '--batch',
                       nargs='+',
                       help='Multiple input strings for batch testing')
    
    parser.add_argument('-q', '--quiet',
                       action='store_true',
                       help='Minimal output (results only)')
    
    args = parser.parse_args()
    
    # Select machine creator
    machine_creators = {
        'palindrome': create_binary_palindrome_tm,
        'parentheses': create_balanced_parentheses_tm
    }
    
    tm_creator = machine_creators[args.machine]
    
    # Determine mode
    if args.batch:
        batch_mode(args.machine, tm_creator, args.batch)
    elif args.input:
        accepted = single_run(args.machine, tm_creator, args.input, verbose=not args.quiet)
        sys.exit(0 if accepted else 1)
    else:
        interactive_mode(args.machine, tm_creator)

if __name__ == '__main__':
    main()
