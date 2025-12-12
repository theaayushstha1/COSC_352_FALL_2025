import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from turing_machine import TuringMachine

class PalindromeTM:
    """
    Binary Palindrome Checker
    
    Algorithm: Cross-off strategy
    1. Mark first symbol (0 or 1)
    2. Scan to end of string
    3. Check if last symbol matches first
    4. If match, mark last and return to start
    5. Repeat until string is empty
    6. If at any point symbols don't match, reject
    
    Time Complexity: O(n²)
    Space Complexity: O(n)
    """
    
    def __init__(self):
        self.name = "Binary Palindrome Checker"
        self.description = "Checks if a binary string reads the same forwards and backwards"
        self.examples = ['101', '0110', '11011', '1001', '0', '1']
        
        # State transitions: {state: {symbol: [next_state, write_symbol, direction]}}
        transitions = {
            'q0': {
                '0': ['q1', '0', 'R'],
                '1': ['q5', '1', 'R'],
                'B': ['accept', 'B', 'N'],
                'X': ['q0', 'X', 'R']
            },
            'q1': {
                '0': ['q1', '0', 'R'],
                '1': ['q1', '1', 'R'],
                'X': ['q1', 'X', 'R'],
                'B': ['q2', 'B', 'L']
            },
            'q2': {
                '0': ['q3', 'X', 'L'],
                '1': ['reject', '1', 'N'],
                'X': ['accept', 'X', 'N'],
                'B': ['accept', 'B', 'N']
            },
            'q3': {
                '0': ['q3', '0', 'L'],
                '1': ['q3', '1', 'L'],
                'X': ['q3', 'X', 'L'],
                'B': ['q4', 'B', 'R']
            },
            'q4': {
                '0': ['q0', 'X', 'R'],
                '1': ['reject', '1', 'N'],
                'X': ['q4', 'X', 'R'],
                'B': ['accept', 'B', 'N']
            },
            'q5': {
                '0': ['q5', '0', 'R'],
                '1': ['q5', '1', 'R'],
                'X': ['q5', 'X', 'R'],
                'B': ['q6', 'B', 'L']
            },
            'q6': {
                '1': ['q7', 'X', 'L'],
                '0': ['reject', '0', 'N'],
                'X': ['accept', 'X', 'N'],
                'B': ['accept', 'B', 'N']
            },
            'q7': {
                '0': ['q7', '0', 'L'],
                '1': ['q7', '1', 'L'],
                'X': ['q7', 'X', 'L'],
                'B': ['q8', 'B', 'R']
            },
            'q8': {
                '1': ['q0', 'X', 'R'],
                '0': ['reject', '0', 'N'],
                'X': ['q8', 'X', 'R'],
                'B': ['accept', 'B', 'N']
            }
        }
        
        self.machine = TuringMachine(
            transitions=transitions,
            start_state='q0',
            accept_state='accept',
            reject_state='reject'
        )
    
    def run(self, input_string):
        """Execute palindrome check on input"""
        # Validate input contains only 0s and 1s
        if not all(c in '01' for c in input_string):
            return {
                'accepted': False,
                'trace': [],
                'final_state': 'reject',
                'error': 'Input must contain only 0 and 1'
            }
        
        return self.machine.run(input_string)