"""
Binary Palindrome Checker - Turing Machine
Checks if a binary string (0s and 1s) is a palindrome.

Algorithm:
1. Mark leftmost unmatched symbol with X
2. Move to rightmost unmatched symbol
3. Check if it matches the marked symbol
4. If match, mark with X and repeat
5. If all symbols matched, accept
6. If mismatch found, reject

Examples:
- "101" → Accept (reads same forwards/backwards)
- "1001" → Accept
- "110" → Reject
- "0" → Accept (single symbol is palindrome)
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from turing_machine import TuringMachine


def create_palindrome_tm():
    """
    Create a Turing Machine that checks binary palindromes.
    
    Fixed to handle odd-length palindromes correctly!
    """
    
    states = ['q0', 'q_seek_right_0', 'q_seek_right_1', 
              'q_check_0', 'q_check_1', 'q_go_left',
              'q_accept', 'q_reject']
    
    alphabet = ['0', '1', 'X', '_']
    blank_symbol = '_'
    
    transitions = {
        # Initial state: mark leftmost symbol
        ('q0', '0'): ('q_seek_right_0', 'X', 'R'),
        ('q0', '1'): ('q_seek_right_1', 'X', 'R'),
        ('q0', 'X'): ('q0', 'X', 'R'),              # Skip already checked
        ('q0', '_'): ('q_accept', '_', 'S'),        # Empty or all checked
        
        # Seeking right for matching 0
        ('q_seek_right_0', '0'): ('q_seek_right_0', '0', 'R'),
        ('q_seek_right_0', '1'): ('q_seek_right_0', '1', 'R'),
        ('q_seek_right_0', 'X'): ('q_seek_right_0', 'X', 'R'),
        ('q_seek_right_0', '_'): ('q_check_0', '_', 'L'),
        
        # Seeking right for matching 1
        ('q_seek_right_1', '0'): ('q_seek_right_1', '0', 'R'),
        ('q_seek_right_1', '1'): ('q_seek_right_1', '1', 'R'),
        ('q_seek_right_1', 'X'): ('q_seek_right_1', 'X', 'R'),
        ('q_seek_right_1', '_'): ('q_check_1', '_', 'L'),
        
        # Check rightmost for 0
        ('q_check_0', '0'): ('q_go_left', 'X', 'L'),
        ('q_check_0', '1'): ('q_reject', '1', 'S'),
        ('q_check_0', 'X'): ('q_check_0', 'X', 'L'),  # FIX: Keep looking left past X's
        ('q_check_0', '_'): ('q_accept', '_', 'S'),   # FIX: Only X's left - middle reached!
        
        # Check rightmost for 1
        ('q_check_1', '1'): ('q_go_left', 'X', 'L'),
        ('q_check_1', '0'): ('q_reject', '0', 'S'),
        ('q_check_1', 'X'): ('q_check_1', 'X', 'L'),  # FIX: Keep looking left past X's
        ('q_check_1', '_'): ('q_accept', '_', 'S'),   # FIX: Only X's left - middle reached!
        
        # Return to left side
        ('q_go_left', '0'): ('q_go_left', '0', 'L'),
        ('q_go_left', '1'): ('q_go_left', '1', 'L'),
        ('q_go_left', 'X'): ('q_go_left', 'X', 'L'),
        ('q_go_left', '_'): ('q0', '_', 'R'),
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
    print("Binary Palindrome Checker - Turing Machine")
    print("=" * 60)
    print()
    
    tm = create_palindrome_tm()
    
    # Test cases: (input, should_accept, description)
    test_cases = [
        ("0", True, "Single 0"),
        ("1", True, "Single 1"),
        ("00", True, "Double 0"),
        ("11", True, "Double 1"),
        ("01", False, "Not palindrome"),
        ("10", False, "Not palindrome"),
        ("101", True, "Classic palindrome"),
        ("111", True, "Three 1s"),
        ("1001", True, "Four digit palindrome"),
        ("1101", False, "Not palindrome"),
        ("10101", True, "Five digit palindrome"),
        ("110011", True, "Six digit palindrome"),
    ]
    
    print("Testing Binary Palindrome Checker:")
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
        
        print(f"{status} | '{input_str:6s}' → {result_str:6s} (expected {expected_str:6s}) | {description}")
    
    print("-" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    print()
    
    # Show detailed trace for one example
    print("Detailed trace for input '101':")
    print("-" * 60)
    
    result = tm.run('101')
    print(f"Result: {'ACCEPTED ✓' if result['accepted'] else 'REJECTED ✗'}")
    print(f"Steps: {result['steps']}")
    print(f"Reason: {result['reason']}")
    print()
    print("State Trace (first 15 steps):")
    
    for entry in result['trace'][:15]:
        tape_visual = list(entry['tape'])
        pos = entry['head_position']
        if 0 <= pos < len(tape_visual):
            tape_visual[pos] = f"[{tape_visual[pos]}]"
        tape_str = ''.join(tape_visual)
        print(f"  Step {entry['step']:3d}: {entry['state']:15s} | {tape_str}")
    
    if len(result['trace']) > 15:
        print(f"  ... ({len(result['trace']) - 15} more steps)")
    
    print()
    print("=" * 60)
    print("✅ Palindrome TM testing complete!")
    print("=" * 60)