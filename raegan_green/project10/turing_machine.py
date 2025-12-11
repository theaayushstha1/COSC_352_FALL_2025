#!/usr/bin/env python3
"""
Turing Machine Simulator
A comprehensive implementation with state tracing and multiple built-in machines.
"""

import sys
from typing import List, Tuple, Optional, Dict
from enum import Enum


class Direction(Enum):
    """Tape head movement direction."""
    LEFT = -1
    RIGHT = 1
    STAY = 0


class TuringMachine:
    """
    A Turing Machine simulator with full state tracing.
    
    The machine operates on a tape with cells containing symbols.
    State transitions are defined by (current_state, read_symbol) -> (new_state, write_symbol, direction)
    """
    
    def __init__(self, 
                 states: set,
                 input_alphabet: set,
                 tape_alphabet: set,
                 transitions: Dict[Tuple[str, str], Tuple[str, str, Direction]],
                 start_state: str,
                 accept_state: str,
                 reject_state: str,
                 blank_symbol: str = '_'):
        """
        Initialize the Turing Machine.
        
        Args:
            states: Set of state names
            input_alphabet: Set of input symbols
            tape_alphabet: Set of tape symbols (includes input_alphabet + blank + work symbols)
            transitions: Dictionary mapping (state, symbol) -> (new_state, write_symbol, direction)
            start_state: Initial state
            accept_state: Accepting state
            reject_state: Rejecting state
            blank_symbol: Symbol representing blank cells
        """
        self.states = states
        self.input_alphabet = input_alphabet
        self.tape_alphabet = tape_alphabet
        self.transitions = transitions
        self.start_state = start_state
        self.accept_state = accept_state
        self.reject_state = reject_state
        self.blank_symbol = blank_symbol
        
        # Execution state
        self.tape: List[str] = []
        self.head_position: int = 0
        self.current_state: str = start_state
        self.step_count: int = 0
        self.trace: List[Dict] = []
        self.max_steps: int = 10000  # Prevent infinite loops
    
    def initialize_tape(self, input_string: str):
        """Initialize the tape with input string."""
        self.tape = list(input_string) if input_string else [self.blank_symbol]
        self.head_position = 0
        self.current_state = self.start_state
        self.step_count = 0
        self.trace = []
        
        # Record initial configuration
        self._record_trace("INIT")
    
    def _record_trace(self, action: str = "STEP"):
        """Record current configuration for trace."""
        # Get tape representation with context
        left_context = max(0, self.head_position - 5)
        right_context = min(len(self.tape), self.head_position + 6)
        
        # Ensure tape has content
        if not self.tape:
            self.tape = [self.blank_symbol]
        
        tape_view = ''.join(self.tape[left_context:right_context])
        head_offset = self.head_position - left_context
        
        self.trace.append({
            'step': self.step_count,
            'action': action,
            'state': self.current_state,
            'head_position': self.head_position,
            'tape_view': tape_view,
            'head_offset': head_offset,
            'read_symbol': self.tape[self.head_position] if 0 <= self.head_position < len(self.tape) else self.blank_symbol
        })
    
    def step(self) -> bool:
        """
        Execute one step of the Turing Machine.
        
        Returns:
            True if machine should continue, False if halted (accept/reject)
        """
        # Extend tape if needed
        if self.head_position < 0:
            self.tape.insert(0, self.blank_symbol)
            self.head_position = 0
        elif self.head_position >= len(self.tape):
            self.tape.append(self.blank_symbol)
        
        # Read current symbol
        current_symbol = self.tape[self.head_position]
        
        # Check if we're in a halting state
        if self.current_state == self.accept_state:
            self._record_trace("ACCEPT")
            return False
        if self.current_state == self.reject_state:
            self._record_trace("REJECT")
            return False
        
        # Get transition
        transition_key = (self.current_state, current_symbol)
        if transition_key not in self.transitions:
            # No transition defined - implicit reject
            self.current_state = self.reject_state
            self._record_trace("REJECT (no transition)")
            return False
        
        new_state, write_symbol, direction = self.transitions[transition_key]
        
        # Execute transition
        self.tape[self.head_position] = write_symbol
        self.current_state = new_state
        self.head_position += direction.value
        self.step_count += 1
        
        # Record trace
        self._record_trace()
        
        # Check for infinite loop
        if self.step_count >= self.max_steps:
            self.current_state = self.reject_state
            self._record_trace("REJECT (max steps exceeded)")
            return False
        
        return True
    
    def run(self, input_string: str) -> Tuple[bool, str]:
        """
        Run the Turing Machine on input string.
        
        Args:
            input_string: Input to process
            
        Returns:
            Tuple of (accepted: bool, result_message: str)
        """
        self.initialize_tape(input_string)
        
        while self.step():
            pass
        
        accepted = self.current_state == self.accept_state
        
        if accepted:
            result = f"ACCEPTED after {self.step_count} steps"
        else:
            result = f"REJECTED after {self.step_count} steps"
        
        return accepted, result
    
    def print_trace(self, verbose: bool = True):
        """Print execution trace."""
        print("\n" + "="*70)
        print("EXECUTION TRACE")
        print("="*70)
        
        for entry in self.trace:
            if verbose or entry['action'] in ['INIT', 'ACCEPT', 'REJECT']:
                step_str = f"Step {entry['step']:4d}" if entry['step'] > 0 else "Initial"
                print(f"\n{step_str} | State: {entry['state']:15s} | Action: {entry['action']}")
                
                if verbose:
                    # Print tape with head indicator
                    print(f"  Tape:  {entry['tape_view']}")
                    print(f"  Head:  {' ' * entry['head_offset']}^")
                    print(f"  Read:  {entry['read_symbol']}")
        
        print("\n" + "="*70)


# ==============================================================================
# Pre-defined Turing Machines
# ==============================================================================

def create_binary_palindrome_checker() -> TuringMachine:
    """
    Creates a Turing Machine that checks if a binary string is a palindrome.
    
    Algorithm:
    1. Mark leftmost unmarked symbol, remember it
    2. Move right to find rightmost unmarked symbol
    3. Check if they match
    4. If match, repeat; if all checked, accept; if mismatch, reject
    
    Complexity: O(n²) time, recognizes language {w | w = w^R, w ∈ {0,1}*}
    """
    states = {'q0', 'q1', 'q2', 'q3', 'q4', 'q5', 'q6', 'q_accept', 'q_reject'}
    input_alphabet = {'0', '1'}
    tape_alphabet = {'0', '1', 'X', 'Y', '_'}
    
    transitions = {
        # Start: mark left symbol and remember it
        ('q0', '0'): ('q1', 'X', Direction.RIGHT),  # Remember 0
        ('q0', '1'): ('q2', 'X', Direction.RIGHT),  # Remember 1
        ('q0', 'X'): ('q0', 'X', Direction.RIGHT),  # Skip marked
        ('q0', 'Y'): ('q0', 'Y', Direction.RIGHT),  # Skip marked
        ('q0', '_'): ('q_accept', '_', Direction.STAY),  # Empty or all checked
        
        # q1: remembered 0, move to rightmost
        ('q1', '0'): ('q1', '0', Direction.RIGHT),
        ('q1', '1'): ('q1', '1', Direction.RIGHT),
        ('q1', 'Y'): ('q1', 'Y', Direction.RIGHT),
        ('q1', '_'): ('q3', '_', Direction.LEFT),  # Found end
        
        # q2: remembered 1, move to rightmost
        ('q2', '0'): ('q2', '0', Direction.RIGHT),
        ('q2', '1'): ('q2', '1', Direction.RIGHT),
        ('q2', 'Y'): ('q2', 'Y', Direction.RIGHT),
        ('q2', '_'): ('q4', '_', Direction.LEFT),  # Found end
        
        # q3: check if rightmost is 0
        ('q3', '0'): ('q5', 'Y', Direction.LEFT),  # Match! Mark and go back
        ('q3', '1'): ('q_reject', '1', Direction.STAY),  # Mismatch
        ('q3', 'Y'): ('q3', 'Y', Direction.LEFT),  # Skip marked
        ('q3', 'X'): ('q_accept', 'X', Direction.STAY),  # All checked (single or even)
        
        # q4: check if rightmost is 1
        ('q4', '1'): ('q5', 'Y', Direction.LEFT),  # Match! Mark and go back
        ('q4', '0'): ('q_reject', '0', Direction.STAY),  # Mismatch
        ('q4', 'Y'): ('q4', 'Y', Direction.LEFT),  # Skip marked
        ('q4', 'X'): ('q_accept', 'X', Direction.STAY),  # All checked
        
        # q5: move back to start
        ('q5', '0'): ('q5', '0', Direction.LEFT),
        ('q5', '1'): ('q5', '1', Direction.LEFT),
        ('q5', 'X'): ('q5', 'X', Direction.LEFT),
        ('q5', 'Y'): ('q5', 'Y', Direction.LEFT),
        ('q5', '_'): ('q6', '_', Direction.RIGHT),  # Reached start
        
        # q6: return to start state
        ('q6', 'X'): ('q0', 'X', Direction.RIGHT),
        ('q6', 'Y'): ('q0', 'Y', Direction.RIGHT),
    }
    
    return TuringMachine(
        states=states,
        input_alphabet=input_alphabet,
        tape_alphabet=tape_alphabet,
        transitions=transitions,
        start_state='q0',
        accept_state='q_accept',
        reject_state='q_reject',
        blank_symbol='_'
    )


def create_binary_increment() -> TuringMachine:
    """
    Creates a Turing Machine that increments a binary number by 1.
    
    Algorithm:
    1. Move to rightmost digit
    2. Add 1 (handle carry)
    3. Propagate carry left if needed
    
    Complexity: O(n) time, computes f(w) = binary(decimal(w) + 1)
    """
    states = {'q0', 'q1', 'q2', 'q_accept', 'q_reject'}
    input_alphabet = {'0', '1'}
    tape_alphabet = {'0', '1', '_'}
    
    transitions = {
        # Move to rightmost digit
        ('q0', '0'): ('q0', '0', Direction.RIGHT),
        ('q0', '1'): ('q0', '1', Direction.RIGHT),
        ('q0', '_'): ('q1', '_', Direction.LEFT),  # Found end
        
        # Add 1 to rightmost
        ('q1', '0'): ('q_accept', '1', Direction.STAY),  # 0+1=1, done
        ('q1', '1'): ('q2', '0', Direction.LEFT),  # 1+1=0, carry
        ('q1', '_'): ('q_accept', '1', Direction.STAY),  # Empty input -> 1
        
        # Propagate carry
        ('q2', '0'): ('q_accept', '1', Direction.STAY),  # 0+carry=1, done
        ('q2', '1'): ('q2', '0', Direction.LEFT),  # 1+carry=0, continue carry
        ('q2', '_'): ('q_accept', '1', Direction.STAY),  # Overflow, prepend 1
    }
    
    return TuringMachine(
        states=states,
        input_alphabet=input_alphabet,
        tape_alphabet=tape_alphabet,
        transitions=transitions,
        start_state='q0',
        accept_state='q_accept',
        reject_state='q_reject',
        blank_symbol='_'
    )


def create_anbn_recognizer() -> TuringMachine:
    """
    Creates a Turing Machine that recognizes the language {a^n b^n | n >= 0}.
    
    Algorithm:
    1. Mark one 'a' and one 'b'
    2. Repeat until all symbols are marked
    3. Accept if equal count, reject otherwise
    
    Complexity: O(n²) time, classic context-free language
    """
    states = {'q0', 'q1', 'q2', 'q3', 'q4', 'q_accept', 'q_reject'}
    input_alphabet = {'a', 'b'}
    tape_alphabet = {'a', 'b', 'X', 'Y', '_'}
    
    transitions = {
        # Start: find first unmarked 'a'
        ('q0', 'a'): ('q1', 'X', Direction.RIGHT),  # Mark 'a'
        ('q0', 'X'): ('q0', 'X', Direction.RIGHT),  # Skip marked 'a'
        ('q0', 'Y'): ('q0', 'Y', Direction.RIGHT),  # Skip marked 'b'
        ('q0', 'b'): ('q_reject', 'b', Direction.STAY),  # b before a
        ('q0', '_'): ('q_accept', '_', Direction.STAY),  # Empty or all matched
        
        # q1: skip remaining 'a's and X's, find first 'b'
        ('q1', 'a'): ('q1', 'a', Direction.RIGHT),
        ('q1', 'X'): ('q1', 'X', Direction.RIGHT),
        ('q1', 'b'): ('q2', 'Y', Direction.LEFT),  # Mark corresponding 'b'
        ('q1', 'Y'): ('q1', 'Y', Direction.RIGHT),  # Skip marked 'b'
        ('q1', '_'): ('q_reject', '_', Direction.STAY),  # No matching 'b'
        
        # q2: return to start
        ('q2', 'a'): ('q2', 'a', Direction.LEFT),
        ('q2', 'b'): ('q2', 'b', Direction.LEFT),
        ('q2', 'X'): ('q2', 'X', Direction.LEFT),
        ('q2', 'Y'): ('q2', 'Y', Direction.LEFT),
        ('q2', '_'): ('q3', '_', Direction.RIGHT),
        
        # q3: move to next unmarked 'a'
        ('q3', 'X'): ('q0', 'X', Direction.RIGHT),
        ('q3', 'Y'): ('q4', 'Y', Direction.RIGHT),  # Check if all done
        
        # q4: verify all b's are marked
        ('q4', 'Y'): ('q4', 'Y', Direction.RIGHT),
        ('q4', '_'): ('q_accept', '_', Direction.STAY),
        ('q4', 'b'): ('q_reject', 'b', Direction.STAY),  # Extra b
    }
    
    return TuringMachine(
        states=states,
        input_alphabet=input_alphabet,
        tape_alphabet=tape_alphabet,
        transitions=transitions,
        start_state='q0',
        accept_state='q_accept',
        reject_state='q_reject',
        blank_symbol='_'
    )


# ==============================================================================
# Main Program
# ==============================================================================

def print_header():
    """Print program header."""
    print("\n" + "="*70)
    print(" " * 20 + "TURING MACHINE SIMULATOR")
    print("="*70)
    print("\nA comprehensive implementation with multiple built-in machines")
    print("and full state trace visualization.\n")


def print_machine_info(name: str, description: str, examples: List[Tuple[str, bool]]):
    """Print information about a Turing Machine."""
    print("\n" + "-"*70)
    print(f"Machine: {name}")
    print("-"*70)
    print(f"Description: {description}")
    print("\nExample inputs:")
    for input_str, should_accept in examples:
        status = "✓ Accept" if should_accept else "✗ Reject"
        display_input = input_str if input_str else "(empty)"
        print(f"  '{display_input}' -> {status}")
    print()


def main():
    """Main program entry point."""
    print_header()
    
    # Define available machines
    machines = {
        '1': {
            'name': 'Binary Palindrome Checker',
            'description': 'Checks if a binary string reads the same forwards and backwards',
            'creator': create_binary_palindrome_checker,
            'examples': [
                ('', True),
                ('0', True),
                ('1', True),
                ('11', True),
                ('101', True),
                ('0110', False),
                ('10101', True),
                ('110011', True),
                ('111000', False),
            ]
        },
        '2': {
            'name': 'Binary Increment',
            'description': 'Adds 1 to a binary number',
            'creator': create_binary_increment,
            'examples': [
                ('', True),  # -> 1
                ('0', True),  # -> 1
                ('1', True),  # -> 10
                ('10', True),  # -> 11
                ('11', True),  # -> 100
                ('101', True),  # -> 110
                ('111', True),  # -> 1000
            ]
        },
        '3': {
            'name': 'a^n b^n Recognizer',
            'description': 'Recognizes strings with equal number of a\'s followed by equal b\'s',
            'creator': create_anbn_recognizer,
            'examples': [
                ('', True),
                ('ab', True),
                ('aabb', True),
                ('aaabbb', True),
                ('aaaabbbb', True),
                ('a', False),
                ('b', False),
                ('aab', False),
                ('abb', False),
                ('ba', False),
                ('aabba', False),
            ]
        }
    }
    
    # Get machine selection
    if len(sys.argv) > 1 and sys.argv[1] in machines:
        choice = sys.argv[1]
    else:
        print("Available Turing Machines:")
        for key, machine in machines.items():
            print(f"  {key}. {machine['name']}")
        print("\nUsage: python turing_machine.py <machine_number> [input_string]")
        print("Example: python turing_machine.py 1 101")
        print("\nOr run interactively:")
        print("  python turing_machine.py")
        print()
        
        choice = input("Select machine (1-3): ").strip()
        if choice not in machines:
            print(f"Invalid choice: {choice}")
            return 1
    
    # Get input string
    if len(sys.argv) > 2:
        input_string = sys.argv[2]
        interactive = False
    else:
        interactive = True
    
    # Create and display machine info
    machine_config = machines[choice]
    print_machine_info(
        machine_config['name'],
        machine_config['description'],
        machine_config['examples']
    )
    
    tm = machine_config['creator']()
    
    # Process input(s)
    if interactive:
        print("Enter input strings (one per line, 'quit' to exit):")
        print("Tip: Use '-' for empty string\n")
        
        while True:
            try:
                user_input = input("Input> ").strip()
                if user_input.lower() == 'quit':
                    break
                
                if user_input == '-':
                    user_input = ''
                
                print(f"\nProcessing: '{user_input if user_input else '(empty)'}'")
                print("-"*70)
                
                accepted, message = tm.run(user_input)
                print(f"\nResult: {message}")
                tm.print_trace(verbose=True)
                
                print("\n")
                
            except KeyboardInterrupt:
                print("\n\nExiting...")
                break
            except EOFError:
                break
    else:
        print(f"Processing: '{input_string if input_string else '(empty)'}'")
        print("-"*70)
        
        accepted, message = tm.run(input_string)
        print(f"\nResult: {message}")
        tm.print_trace(verbose=True)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
    