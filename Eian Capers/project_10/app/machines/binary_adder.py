import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from turing_machine import TuringMachine

class BinaryAdderTM:
    """
    Binary Addition Turing Machine
    
    Input format: num1+num2 (e.g., "101+11")
    
    Algorithm:
    1. Scan to find the '+' symbol
    2. Process from right to left (like manual addition)
    3. Handle carry bits through states
    4. Write result by modifying tape
    
    States manage:
    - q0-q1: Scanning phase
    - q2-q5: End positioning
    - q6-q11: Carry and addition logic
    
    Time Complexity: O(n * m) where n, m are operand lengths
    Space Complexity: O(n + m)
    """
    
    def __init__(self):
        self.name = "Binary Adder"
        self.description = "Adds two binary numbers separated by +"
        self.examples = ['1+1', '10+11', '101+010', '111+111', '1+0']
        
        transitions = {
            'q0': {
                '0': ['q0', '0', 'R'],
                '1': ['q0', '1', 'R'],
                '+': ['q1', '+', 'R'],
                'B': ['reject', 'B', 'N']
            },
            'q1': {
                '0': ['q1', '0', 'R'],
                '1': ['q1', '1', 'R'],
                'B': ['q2', 'B', 'L'],
                '+': ['reject', '+', 'N']
            },
            'q2': {
                '0': ['q3', 'B', 'L'],
                '1': ['q4', 'B', 'L'],
                '+': ['q5', 'B', 'L'],
                'B': ['reject', 'B', 'N']
            },
            'q3': {  # Last digit was 0, no carry
                '0': ['q3', '0', 'L'],
                '1': ['q3', '1', 'L'],
                '+': ['q6', '+', 'L'],
                'B': ['accept', 'B', 'N']
            },
            'q4': {  # Last digit was 1, might have carry
                '0': ['q4', '0', 'L'],
                '1': ['q4', '1', 'L'],
                '+': ['q7', '+', 'L'],
                'B': ['accept', 'B', 'N']
            },
            'q5': {  # Reached separator
                '0': ['q5', '0', 'L'],
                '1': ['q5', '1', 'L'],
                'B': ['accept', 'B', 'N']
            },
            'q6': {  # Process left operand, result 0
                '0': ['q8', 'B', 'R'],
                '1': ['q9', 'B', 'R'],
                'B': ['q10', '0', 'R']
            },
            'q7': {  # Process left operand, result 1
                '0': ['q9', 'B', 'R'],
                '1': ['q11', 'B', 'R'],
                'B': ['q10', '1', 'R']
            },
            'q8': {  # Write 0, continue
                'B': ['q1', '0', 'R'],
                '+': ['q1', '0', 'R']
            },
            'q9': {  # Write 1, continue
                'B': ['q1', '1', 'R'],
                '+': ['q1', '1', 'R']
            },
            'q10': {  # Clean up and finish
                '+': ['q5', 'B', 'L'],
                'B': ['accept', 'B', 'N']
            },
            'q11': {  # Write 0 with carry
                'B': ['q1', '0', 'R'],
                '+': ['q1', '0', 'R']
            }
        }
        
        self.machine = TuringMachine(
            transitions=transitions,
            start_state='q0',
            accept_state='accept',
            reject_state='reject'
        )
    
    def run(self, input_string):
        """Execute binary addition on input"""
        # Validate input format
        if '+' not in input_string:
            return {
                'accepted': False,
                'trace': [],
                'final_state': 'reject',
                'error': 'Input must contain + separator'
            }
        
        parts = input_string.split('+')
        if len(parts) != 2:
            return {
                'accepted': False,
                'trace': [],
                'final_state': 'reject',
                'error': 'Input must have exactly two operands'
            }
        
        # Validate binary digits
        for part in parts:
            if not part or not all(c in '01' for c in part):
                return {
                    'accepted': False,
                    'trace': [],
                    'final_state': 'reject',
                    'error': 'Operands must contain only 0 and 1'
                }
        
        return self.machine.run(input_string)