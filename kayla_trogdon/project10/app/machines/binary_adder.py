"""
Binary Number Adder - Turing MAchine
Adds 1 to a binary number

Examples: 
- "101" --> "110" ( 5 + 1 = 6 )
- "111" --> "1000" ( 7 + 1 = 8 )
- "1001" --> "1010" ( 9 + 1 = 10 )
- "0" --> "1"
"""
import sys
import os 

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from turing_machine import TuringMachine

def create_binary_adder_tm(): 
    """
    Create a Turing MAchine that adds 1 to a binary number. 
    States: 
    - q_start: Move to rightmost digit
    - q_add: Add 1 (handle carry propagation)
    - q_accept: Addition complete
    - q_reject: Invalid input
    """
    states = [
        'q_start',
        'q_add',
        'q_done',
        'q_accept',
        'q_reject'
    ]

    alphabet = ['0', '1', '_'] 
    blank_symbol = '_'

    transitions = {
        # Move to rightmost digit
        ('q_start', '0'): ('q_start', '0', 'R'),
        ('q_start', '1'): ('q_start', '1', 'R'),
        ('q_start', '_'): ('q_add', '_', 'L'),      # Reached end, start adding
        
        # Add 1 to rightmost position
        ('q_add', '0'): ('q_done', '1', 'L'),       # 0+1=1, no carry
        ('q_add', '1'): ('q_add', '0', 'L'),        # 1+1=0, carry 1
        ('q_add', '_'): ('q_done', '1', 'R'),       # Carry to new position
        
        # Clean up and accept
        ('q_done', '0'): ('q_done', '0', 'L'),      # Move back to start
        ('q_done', '1'): ('q_done', '1', 'L'),
        ('q_done', '_'): ('q_accept', '_', 'R'),    # At beginning, accept
    }

    return TuringMachine(
        states=states,
        alphabet=alphabet,
        blank_symbol=blank_symbol,
        transitions=transitions,
        initial_state='q_start',
        accept_states=['q_accept'],
        reject_states=['q_reject']
    )


# =============================================================================
# TESTING CODE
# =============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("Binary Number Adder - Turing Machine")
    print("Adds 1 to a binary number")
    print("=" * 60)
    print()
    
    tm = create_binary_adder_tm()
    
    # Test cases: (input, expected_output, description)
    test_cases = [
        ("0", "1", "0 + 1 = 1"),
        ("1", "10", "1 + 1 = 2"),
        ("10", "11", "2 + 1 = 3"),
        ("11", "100", "3 + 1 = 4"),
        ("100", "101", "4 + 1 = 5"),
        ("101", "110", "5 + 1 = 6"),
        ("110", "111", "6 + 1 = 7"),
        ("111", "1000", "7 + 1 = 8"),
        ("1000", "1001", "8 + 1 = 9"),
        ("1001", "1010", "9 + 1 = 10"),
        ("1111", "10000", "15 + 1 = 16"),
    ]
    
    print("Testing Binary Adder:")
    print("-" * 60)
    
    passed = 0
    failed = 0
    
    for input_str, expected_output, description in test_cases:
        result = tm.run(input_str)
        actual_output = result['final_tape'].strip('_')
        
        if actual_output == expected_output:
            status = "✓ PASS"
            passed += 1
        else:
            status = "✗ FAIL"
            failed += 1
        
        print(f"{status} | '{input_str:5s}' + 1 = '{actual_output:6s}' (expected '{expected_output:6s}') | {description}")
    
    print("-" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    print()
    
    # Show detailed trace for one example
    print("Detailed trace for '111' + 1:")
    print("-" * 60)
    
    result = tm.run('111')
    print(f"Input:  111")
    print(f"Output: {result['final_tape'].strip('_')}")
    print(f"Steps:  {result['steps']}")
    print()
    print("State Trace (first 20 steps):")
    
    for entry in result['trace'][:20]:
        tape_visual = list(entry['tape'])
        pos = entry['head_position']
        if 0 <= pos < len(tape_visual):
            tape_visual[pos] = f"[{tape_visual[pos]}]"
        tape_str = ''.join(tape_visual)
        print(f"  Step {entry['step']:3d}: {entry['state']:10s} | {tape_str}")
    
    if len(result['trace']) > 20:
        print(f"  ... ({len(result['trace']) - 20} more steps)")
    
    print()
    print("=" * 60)
    print("✅ Binary Adder TM testing complete!")
    print("=" * 60)