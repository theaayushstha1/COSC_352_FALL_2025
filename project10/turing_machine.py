"""
Turing Machine Simulator
A comprehensive implementation of a Turing Machine with state trace visualization
"""

from typing import Dict, List, Tuple, Optional, Set
from dataclasses import dataclass
from enum import Enum

class Direction(Enum):
    """Direction for tape head movement"""
    LEFT = -1
    RIGHT = 1
    STAY = 0

@dataclass
class Transition:
    """Represents a transition in the Turing Machine"""
    current_state: str
    read_symbol: str
    next_state: str
    write_symbol: str
    direction: Direction
    
    def __repr__(self):
        dir_symbol = '←' if self.direction == Direction.LEFT else '→' if self.direction == Direction.RIGHT else '·'
        return f"δ({self.current_state}, {self.read_symbol}) → ({self.next_state}, {self.write_symbol}, {dir_symbol})"

class TuringMachine:
    """
    A Turing Machine simulator with configurable states, alphabet, and transitions.
    
    Components:
    - Q: Finite set of states
    - Σ: Input alphabet
    - Γ: Tape alphabet (Σ ⊆ Γ)
    - δ: Transition function (Q × Γ → Q × Γ × {L, R, S})
    - q0: Initial state
    - qaccept: Accept state
    - qreject: Reject state
    - blank: Blank symbol
    """
    
    def __init__(self, 
                 states: Set[str],
                 input_alphabet: Set[str],
                 tape_alphabet: Set[str],
                 transitions: List[Transition],
                 initial_state: str,
                 accept_state: str,
                 reject_state: str,
                 blank_symbol: str = '_'):
        
        self.states = states
        self.input_alphabet = input_alphabet
        self.tape_alphabet = tape_alphabet
        self.transitions = self._build_transition_dict(transitions)
        self.initial_state = initial_state
        self.accept_state = accept_state
        self.reject_state = reject_state
        self.blank = blank_symbol
        
        # Execution state
        self.tape: List[str] = []
        self.head_position: int = 0
        self.current_state: str = initial_state
        self.step_count: int = 0
        self.trace: List[Dict] = []
        self.max_steps: int = 10000
        
    def _build_transition_dict(self, transitions: List[Transition]) -> Dict[Tuple[str, str], Transition]:
        """Build a dictionary for O(1) transition lookups"""
        trans_dict = {}
        for t in transitions:
            key = (t.current_state, t.read_symbol)
            trans_dict[key] = t
        return trans_dict
    
    def _initialize_tape(self, input_string: str):
        """Initialize the tape with the input string"""
        self.tape = list(input_string) if input_string else [self.blank]
        self.head_position = 0
        self.current_state = self.initial_state
        self.step_count = 0
        self.trace = []
        
        # Record initial configuration
        self._record_state("INIT", None)
    
    def _read_symbol(self) -> str:
        """Read the symbol at the current head position"""
        if self.head_position < 0 or self.head_position >= len(self.tape):
            return self.blank
        return self.tape[self.head_position]
    
    def _write_symbol(self, symbol: str):
        """Write a symbol at the current head position"""
        # Extend tape if necessary
        while self.head_position >= len(self.tape):
            self.tape.append(self.blank)
        while self.head_position < 0:
            self.tape.insert(0, self.blank)
            self.head_position = 0
            
        self.tape[self.head_position] = symbol
    
    def _move_head(self, direction: Direction):
        """Move the tape head in the specified direction"""
        self.head_position += direction.value
        
        # Extend tape if we move beyond boundaries
        if self.head_position < 0:
            self.tape.insert(0, self.blank)
            self.head_position = 0
        elif self.head_position >= len(self.tape):
            self.tape.append(self.blank)
    
    def _record_state(self, action: str, transition: Optional[Transition]):
        """Record the current configuration for trace"""
        tape_display = ''.join(self.tape).rstrip(self.blank)
        if not tape_display:
            tape_display = self.blank
            
        config = {
            'step': self.step_count,
            'state': self.current_state,
            'tape': tape_display,
            'head_pos': self.head_position,
            'action': action,
            'transition': str(transition) if transition else 'N/A'
        }
        self.trace.append(config)
    
    def _get_tape_visualization(self) -> str:
        """Get a visual representation of the tape with head position"""
        tape_str = ''.join(self.tape).rstrip(self.blank) or self.blank
        
        # Create head pointer
        pointer = ' ' * self.head_position + '^'
        
        return f"{tape_str}\n{pointer}"
    
    def run(self, input_string: str) -> Tuple[bool, List[Dict]]:
        """
        Run the Turing Machine on the input string.
        
        Returns:
            Tuple of (accepted: bool, trace: List[Dict])
        """
        self._initialize_tape(input_string)
        
        while self.step_count < self.max_steps:
            # Check for halting states
            if self.current_state == self.accept_state:
                self._record_state("ACCEPT", None)
                return True, self.trace
            
            if self.current_state == self.reject_state:
                self._record_state("REJECT", None)
                return False, self.trace
            
            # Read current symbol
            current_symbol = self._read_symbol()
            
            # Look up transition
            key = (self.current_state, current_symbol)
            if key not in self.transitions:
                # No transition defined - implicit reject
                self.current_state = self.reject_state
                self._record_state("REJECT (No transition)", None)
                return False, self.trace
            
            transition = self.transitions[key]
            
            # Execute transition
            self._write_symbol(transition.write_symbol)
            self.current_state = transition.next_state
            self._move_head(transition.direction)
            
            self.step_count += 1
            self._record_state("STEP", transition)
        
        # Exceeded max steps - reject
        self.current_state = self.reject_state
        self._record_state("REJECT (Max steps exceeded)", None)
        return False, self.trace
    
    def format_trace(self) -> str:
        """Format the execution trace as a readable string"""
        output = []
        output.append("=" * 80)
        output.append("TURING MACHINE EXECUTION TRACE")
        output.append("=" * 80)
        
        for config in self.trace:
            output.append(f"\nStep {config['step']}: {config['action']}")
            output.append(f"  State: {config['state']}")
            output.append(f"  Tape:  {config['tape']}")
            output.append(f"  Head:  {' ' * config['head_pos']}^")
            if config['transition'] != 'N/A':
                output.append(f"  Trans: {config['transition']}")
        
        output.append("\n" + "=" * 80)
        
        final_state = self.trace[-1] if self.trace else None
        if final_state:
            result = "ACCEPTED ✓" if final_state['state'] == self.accept_state else "REJECTED ✗"
            output.append(f"RESULT: {result}")
            output.append(f"Total Steps: {final_state['step']}")
        
        output.append("=" * 80)
        
        return "\n".join(output)


def create_binary_palindrome_tm() -> TuringMachine:
    """
    Creates a Turing Machine that recognizes binary palindromes.
    
    This is a relatively complex TM that demonstrates:
    - Multi-pass algorithm
    - Marking symbols
    - Left and right traversal
    - State management
    
    Language: L = {w ∈ {0,1}* | w = w^R} (binary palindromes)
    
    Algorithm:
    1. If tape is empty or single symbol, accept
    2. Mark leftmost unmarked symbol and remember it (0 or 1)
    3. Move right to find rightmost unmarked symbol
    4. Check if it matches - if yes, mark it; if no, reject
    5. Move back to left side
    6. Repeat until done
    """
    
    states = {
        'q0',      # Initial state / Find leftmost unmarked
        'q1',      # Marked 0, moving right to find end
        'q2',      # Marked 1, moving right to find end
        'q3',      # At rightmost, check if matches 0
        'q4',      # At rightmost, check if matches 1
        'q5',      # Match successful, moving back left
        'q6',      # Check if we're done (middle reached)
        'qaccept', # Accept state
        'qreject'  # Reject state
    }
    
    input_alphabet = {'0', '1'}
    tape_alphabet = {'0', '1', 'X', '_'}  # X marks processed symbols
    
    transitions = [
        # Initial state - find leftmost unmarked symbol
        Transition('q0', '_', 'qaccept', '_', Direction.STAY),  # Empty = palindrome
        Transition('q0', 'X', 'q0', 'X', Direction.RIGHT),      # Skip marked
        Transition('q0', '0', 'q1', 'X', Direction.RIGHT),      # Mark 0, remember
        Transition('q0', '1', 'q2', 'X', Direction.RIGHT),      # Mark 1, remember
        
        # After marking 0, move right to find unmarked symbols
        Transition('q1', '0', 'q1', '0', Direction.RIGHT),
        Transition('q1', '1', 'q1', '1', Direction.RIGHT),
        Transition('q1', 'X', 'q1', 'X', Direction.RIGHT),
        Transition('q1', '_', 'q3', '_', Direction.LEFT),       # Hit end, go back
        
        # After marking 1, move right to find unmarked symbols
        Transition('q2', '0', 'q2', '0', Direction.RIGHT),
        Transition('q2', '1', 'q2', '1', Direction.RIGHT),
        Transition('q2', 'X', 'q2', 'X', Direction.RIGHT),
        Transition('q2', '_', 'q4', '_', Direction.LEFT),       # Hit end, go back
        
        # At rightmost position, check if it's 0 (matching first marked 0)
        Transition('q3', '0', 'q5', 'X', Direction.LEFT),       # Matches! Mark and continue
        Transition('q3', '1', 'qreject', '1', Direction.STAY),  # Doesn't match, reject
        Transition('q3', 'X', 'q3', 'X', Direction.LEFT),       # Skip marked, find rightmost unmarked
        Transition('q3', '_', 'qaccept', '_', Direction.STAY),  # Reached start, all matched!
        
        # At rightmost position, check if it's 1 (matching first marked 1)
        Transition('q4', '1', 'q5', 'X', Direction.LEFT),       # Matches! Mark and continue
        Transition('q4', '0', 'qreject', '0', Direction.STAY),  # Doesn't match, reject
        Transition('q4', 'X', 'q4', 'X', Direction.LEFT),       # Skip marked, find rightmost unmarked
        Transition('q4', '_', 'qaccept', '_', Direction.STAY),  # Reached start, all matched!
        
        # Moving back left after successful match
        Transition('q5', '0', 'q5', '0', Direction.LEFT),
        Transition('q5', '1', 'q5', '1', Direction.LEFT),
        Transition('q5', 'X', 'q5', 'X', Direction.LEFT),
        Transition('q5', '_', 'q6', '_', Direction.RIGHT),      # Back at start
        
        # Check if we're done - if we immediately see X or blank, we're done
        Transition('q6', 'X', 'q6', 'X', Direction.RIGHT),      # Skip marked
        Transition('q6', '_', 'qaccept', '_', Direction.STAY),  # Only marked left = done!
        Transition('q6', '0', 'q1', 'X', Direction.RIGHT),      # More to check, mark 0
        Transition('q6', '1', 'q2', 'X', Direction.RIGHT),      # More to check, mark 1
    ]
    
    return TuringMachine(
        states=states,
        input_alphabet=input_alphabet,
        tape_alphabet=tape_alphabet,
        transitions=transitions,
        initial_state='q0',
        accept_state='qaccept',
        reject_state='qreject',
        blank_symbol='_'
    )


def create_balanced_parentheses_tm() -> TuringMachine:
    """
    Creates a Turing Machine that recognizes balanced parentheses.
    
    Language: L = {w ∈ {(, )}* | w has balanced parentheses}
    
    Algorithm:
    1. Find leftmost '('
    2. Mark it with 'X'
    3. Find rightmost ')'
    4. Mark it with 'Y'
    5. Repeat until no unmarked pairs left
    6. Accept if all matched, reject otherwise
    """
    
    states = {
        'q0',      # Initial/start
        'q1',      # Found '(', looking for ')'
        'q2',      # Moving right to find ')'
        'q3',      # Found ')', moving back to start
        'q4',      # Checking if done
        'qaccept',
        'qreject'
    }
    
    input_alphabet = {'(', ')'}
    tape_alphabet = {'(', ')', 'X', 'Y', '_'}
    
    transitions = [
        # Initial state - find leftmost '('
        Transition('q0', '(', 'q1', 'X', Direction.RIGHT),
        Transition('q0', 'X', 'q0', 'X', Direction.RIGHT),
        Transition('q0', 'Y', 'q0', 'Y', Direction.RIGHT),
        Transition('q0', ')', 'qreject', ')', Direction.STAY),
        Transition('q0', '_', 'q4', '_', Direction.LEFT),
        
        # Looking for matching ')'
        Transition('q1', '(', 'q1', '(', Direction.RIGHT),
        Transition('q1', ')', 'q1', ')', Direction.RIGHT),
        Transition('q1', 'Y', 'q1', 'Y', Direction.RIGHT),
        Transition('q1', '_', 'q2', '_', Direction.LEFT),
        
        # Found end, mark rightmost ')'
        Transition('q2', ')', 'q3', 'Y', Direction.LEFT),
        Transition('q2', 'Y', 'q2', 'Y', Direction.LEFT),
        Transition('q2', '(', 'qreject', '(', Direction.STAY),
        Transition('q2', 'X', 'qreject', 'X', Direction.STAY),
        
        # Move back to start
        Transition('q3', '(', 'q3', '(', Direction.LEFT),
        Transition('q3', ')', 'q3', ')', Direction.LEFT),
        Transition('q3', 'X', 'q3', 'X', Direction.LEFT),
        Transition('q3', 'Y', 'q3', 'Y', Direction.LEFT),
        Transition('q3', '_', 'q0', '_', Direction.RIGHT),
        
        # Check if done - should only see X and Y
        Transition('q4', 'X', 'q4', 'X', Direction.LEFT),
        Transition('q4', 'Y', 'q4', 'Y', Direction.LEFT),
        Transition('q4', '_', 'qaccept', '_', Direction.STAY),
        Transition('q4', '(', 'qreject', '(', Direction.STAY),
        Transition('q4', ')', 'qreject', ')', Direction.STAY),
    ]
    
    return TuringMachine(
        states=states,
        input_alphabet=input_alphabet,
        tape_alphabet=tape_alphabet,
        transitions=transitions,
        initial_state='q0',
        accept_state='qaccept',
        reject_state='qreject',
        blank_symbol='_'
    )


if __name__ == "__main__":
    # Test the binary palindrome TM
    print("Testing Binary Palindrome Turing Machine")
    print("=" * 80)
    
    tm = create_binary_palindrome_tm()
    
    test_cases = [
        ("101", True),
        ("1001", True),
        ("110", False),
        ("0", True),
        ("1", True),
        ("", True),
        ("10101", True),
        ("111", True),
        ("0110", True),  # Fixed: This IS a palindrome!
        ("1000", False),
        ("01", False),
        ("10", False)
    ]
    
    for input_str, expected in test_cases:
        accepted, trace = tm.run(input_str)
        result = "✓" if accepted == expected else "✗"
        print(f"\nInput: '{input_str}' | Expected: {expected} | Got: {accepted} {result}")
        if len(trace) <= 20:  # Only print trace for short runs
            print(tm.format_trace())
