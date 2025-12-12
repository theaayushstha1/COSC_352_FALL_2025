import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from turing_machine import TuringMachine

class BalancedParensTM:
    """
    Balanced Parentheses Checker
    
    Algorithm: Mark-and-sweep
    1. Scan for first '('
    2. Mark it with 'X'
    3. Scan right for first ')'
    4. Mark it with 'X'
    5. Return to start
    6. Repeat until no unmatched parentheses remain
    7. If all matched, accept; otherwise reject
    
    This simulates a stack using the tape as memory
    
    Time Complexity: O(n)
    Space Complexity: O(n)
    """
    
    def __init__(self):
        self.name = "Balanced Parentheses Checker"
        self.description = "Validates that parentheses are properly matched"
        self.examples = ['()', '(())', '()()', '((()))', '(()())']
        
        transitions = {
            'q0': {
                '(': ['q1', 'X', 'R'],
                ')': ['reject', ')', 'N'],
                'X': ['q0', 'X', 'R'],
                'B': ['accept', 'B', 'N']
            },
            'q1': {
                '(': ['q1', '(', 'R'],
                ')': ['q2', 'X', 'L'],
                'X': ['q1', 'X', 'R'],
                'B': ['reject', 'B', 'N']
            },
            'q2': {
                '(': ['q2', '(', 'L'],
                'X': ['q0', 'X', 'R'],
                'B': ['q0', 'B', 'R']
            }
        }
        
        self.machine = TuringMachine(
            transitions=transitions,
            start_state='q0',
            accept_state='accept',
            reject_state='reject'
        )
    
    def run(self, input_string):
        """Execute parentheses validation on input"""
        # Validate input contains only parentheses
        if not all(c in '()' for c in input_string):
            return {
                'accepted': False,
                'trace': [],
                'final_state': 'reject',
                'error': 'Input must contain only ( and )'
            }
        
        return self.machine.run(input_string)