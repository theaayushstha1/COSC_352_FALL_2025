"""
Balanced Parentheses Checker - Turing Machine
Chickes if a string of parentheses is balanced

Examples: 
Examples:
- "()" → Accept
- "(())" → Accept
- "()()" → Accept
- "(()" → Reject (unmatched)
- "())" → Reject (extra closing)
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from turing_machine import TuringMachine

def create_balanced_parens_tm():
    """
    Create a Turing Machine that checks for balanced parentheses. 
    States: 
    - q0: Find first unmarked '('
    - q_find_close: Looking for matching ')'
    - q_go_left: Matched pair, return to start
    - q_accept: All balanced
    - q_reject: Unbalanced 
    """

    states = [
        'q0',
        'q_find_close',
        'q_go_left',
        'q_accept',
        'q_reject'
    ]

    alphabet = ['(', ')', 'X', 'Y', '_']
    blank_symbol = '_'
    
    transitions = {
        # Initial: find first unmarked (
        ('q0', '('): ('q_find_close', 'X', 'R'),    # Mark ( with X, find )
        ('q0', 'X'): ('q0', 'X', 'R'),              # Skip already matched
        ('q0', 'Y'): ('q0', 'Y', 'R'),              # Skip already matched
        ('q0', '_'): ('q_accept', '_', 'S'),        # All matched!
        ('q0', ')'): ('q_reject', ')', 'S'),        # ) without matching (
        
        # Looking for matching )
        ('q_find_close', '('): ('q_find_close', '(', 'R'),  # Skip nested (
        ('q_find_close', ')'): ('q_go_left', 'Y', 'L'),     # Found match!
        ('q_find_close', 'Y'): ('q_find_close', 'Y', 'R'),  # Skip already matched
        ('q_find_close', '_'): ('q_reject', '_', 'S'),      # No matching )
        
        # Return to start
        ('q_go_left', '('): ('q_go_left', '(', 'L'),
        ('q_go_left', 'X'): ('q_go_left', 'X', 'L'),
        ('q_go_left', 'Y'): ('q_go_left', 'Y', 'L'),
        ('q_go_left', '_'): ('q0', '_', 'R'),               # Back to start
    }

    return TuringMachine(
        states=states,
        alphabet=alphabet,
        blank_symbol=blank_symbol,
        transitions=transitions,
        initial_state='q0',
        accept_states=['q_accept'],
        reject_states=['q_reject']
    )


# =============================================================================
# TESTING CODE
# =============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("Balanced Parentheses Checker - Turing Machine")
    print("=" * 60)
    print()
    
    tm = create_balanced_parens_tm()
    
    # Test cases: (input, should_accept, description)
    test_cases = [
        ("()", True, "Simple pair"),
        ("(())", True, "Nested pair"),
        ("()()", True, "Two pairs"),
        ("((()))", True, "Double nested"),
        ("(()())", True, "Multiple nested"),
        ("(", False, "Unmatched opening"),
        (")", False, "Unmatched closing"),
        ("(()", False, "Missing closing"),
        ("())", False, "Extra closing"),
        (")(", False, "Wrong order"),
        ("(()()())", True, "Complex balanced"),
    ]
    
    print("Testing Balanced Parentheses Checker:")
    print("-" * 60)
    
    passed = 0
    failed = 0
    
    for input_str, expected, description in test_cases:
        result = tm.run(input_str)
        actual = result['accepted']
        
        if actual == expected:
            status = "✓ PASS"
            passed += 1
        else:
            status = "✗ FAIL"
            failed += 1
        
        result_str = "ACCEPT" if actual else "REJECT"
        expected_str = "ACCEPT" if expected else "REJECT"
        
        print(f"{status} | '{input_str:10s}' → {result_str:6s} (expected {expected_str:6s}) | {description}")
    
    print("-" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    print()
    
    # Show detailed trace for one example
    print("Detailed trace for input '(())':")
    print("-" * 60)
    
    result = tm.run('(())')
    print(f"Result: {'ACCEPTED ✓' if result['accepted'] else 'REJECTED ✗'}")
    print(f"Steps: {result['steps']}")
    print(f"Reason: {result['reason']}")
    print()
    print("State Trace (first 20 steps):")
    
    for entry in result['trace'][:20]:
        tape_visual = list(entry['tape'])
        pos = entry['head_position']
        if 0 <= pos < len(tape_visual):
            tape_visual[pos] = f"[{tape_visual[pos]}]"
        tape_str = ''.join(tape_visual)
        print(f"  Step {entry['step']:3d}: {entry['state']:15s} | {tape_str}")
    
    if len(result['trace']) > 20:
        print(f"  ... ({len(result['trace']) - 20} more steps)")
    
    print()
    print("=" * 60)
    print("✅ Balanced Parens TM testing complete!")
    print("=" * 60)
