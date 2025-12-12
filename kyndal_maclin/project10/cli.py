#!/usr/bin/env python3
"""
CLI Interface for Turing Machine Simulator
"""

import argparse
import json
from turing_machine import (
    create_simple_tm,
    create_binary_palindrome_tm,
    create_balanced_parentheses_tm,
    print_trace
)


def main():
    parser = argparse.ArgumentParser(
        description='Turing Machine Simulator - Verify inputs against configured TM',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python cli.py --complexity easy --input "0011"
  python cli.py --complexity medium --input "101" --verbose
  python cli.py --complexity hard --input "(())" --trace trace.json

Complexity Levels:
  easy   - Accepts strings with equal number of 0s and 1s
  medium - Accepts binary palindromes
  hard   - Accepts balanced parentheses
        """
    )
    
    parser.add_argument(
        '--complexity',
        choices=['easy', 'medium', 'hard'],
        required=True,
        help='Complexity level of the Turing Machine'
    )
    
    parser.add_argument(
        '--input',
        type=str,
        required=True,
        help='Input string to verify'
    )
    
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Print detailed state trace to console'
    )
    
    parser.add_argument(
        '--trace',
        type=str,
        help='Save state trace to JSON file'
    )
    
    args = parser.parse_args()
    
    # Create appropriate Turing Machine
    print(f"\n{'='*80}")
    print(f"TURING MACHINE SIMULATOR")
    print(f"{'='*80}")
    
    if args.complexity == 'easy':
        print("Complexity: EASY - Equal 0s and 1s")
        print("Description: Accepts strings with equal number of 0s and 1s")
        tm = create_simple_tm()
    elif args.complexity == 'medium':
        print("Complexity: MEDIUM - Binary Palindrome")
        print("Description: Accepts binary strings that are palindromes")
        tm = create_binary_palindrome_tm()
    else:  # hard
        print("Complexity: HARD - Balanced Parentheses")
        print("Description: Accepts strings with balanced parentheses")
        tm = create_balanced_parentheses_tm()
    
    print(f"\nInput String: '{args.input}'")
    print(f"{'='*80}\n")
    
    # Run the Turing Machine
    print("Running Turing Machine...")
    accepted, trace, reason = tm.run(args.input)
    
    # Print results
    print(f"\n{'='*80}")
    print(f"RESULTS")
    print(f"{'='*80}")
    print(f"Input: '{args.input}'")
    print(f"Status: {'ACCEPTED ✓' if accepted else 'REJECTED ✗'}")
    print(f"Reason: {reason}")
    print(f"Total Steps: {len(trace) - 1}")
    print(f"Final State: {trace[-1]['state']}")
    print(f"{'='*80}\n")
    
    # Print evaluation
    print(f"{'='*80}")
    print(f"EVALUATION")
    print(f"{'='*80}")
    if accepted:
        print("✓ PASS - Input was accepted by the Turing Machine")
        print(f"  The input '{args.input}' satisfies the language constraints.")
        print(f"  The machine reached the accept state after {len(trace) - 1} steps.")
    else:
        print("✗ FAIL - Input was rejected by the Turing Machine")
        print(f"  The input '{args.input}' does NOT satisfy the language constraints.")
        print(f"  {reason}")
    print(f"{'='*80}\n")
    
    # Save trace to file if requested
    if args.trace:
        with open(args.trace, 'w') as f:
            json.dump({
                'input': args.input,
                'complexity': args.complexity,
                'accepted': accepted,
                'reason': reason,
                'steps': len(trace) - 1,
                'trace': trace
            }, f, indent=2)
        print(f"State trace saved to: {args.trace}\n")
    
    # Print verbose trace if requested
    if args.verbose:
        print_trace(trace)
    
    # Exit with appropriate code
    exit(0 if accepted else 1)


if __name__ == "__main__":
    main()