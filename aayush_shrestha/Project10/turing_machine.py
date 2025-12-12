"""
Turing Machine Simulator
Implements a deterministic Turing Machine with configurable states and transitions.
"""

class TuringMachine:
    def __init__(self, states, alphabet, blank_symbol, initial_state, accept_states, reject_states, transitions):
        """
        Initialize Turing Machine
        
        Args:
            states: Set of states
            alphabet: Set of tape symbols
            blank_symbol: Symbol representing blank
            initial_state: Starting state
            accept_states: Set of accepting states
            reject_states: Set of rejecting states
            transitions: Dict mapping (state, symbol) -> (new_state, write_symbol, direction)
        """
        self.states = states
        self.alphabet = alphabet
        self.blank_symbol = blank_symbol
        self.initial_state = initial_state
        self.accept_states = accept_states
        self.reject_states = reject_states
        self.transitions = transitions
        
        # Runtime state
        self.tape = []
        self.head_position = 0
        self.current_state = initial_state
        self.trace = []
        self.step_count = 0
        self.max_steps = 10000  # Prevent infinite loops
        
    def load_input(self, input_string):
        """Load input string onto tape"""
        self.tape = list(input_string) if input_string else [self.blank_symbol]
        self.head_position = 0
        self.current_state = self.initial_state
        self.trace = []
        self.step_count = 0
        
        # Record initial configuration
        self._record_trace("INIT")
        
    def step(self):
        """Execute one step of the Turing Machine"""
        if self.step_count >= self.max_steps:
            return False, "MAX_STEPS_EXCEEDED"
        
        # Extend tape if necessary
        if self.head_position < 0:
            self.tape.insert(0, self.blank_symbol)
            self.head_position = 0
        elif self.head_position >= len(self.tape):
            self.tape.append(self.blank_symbol)
        
        # Read current symbol
        current_symbol = self.tape[self.head_position]
        
        # Check for transition
        transition_key = (self.current_state, current_symbol)
        if transition_key not in self.transitions:
            # No transition defined - check if accept/reject
            if self.current_state in self.accept_states:
                self._record_trace("ACCEPT")
                return False, "ACCEPT"
            elif self.current_state in self.reject_states:
                self._record_trace("REJECT")
                return False, "REJECT"
            else:
                self._record_trace("REJECT (No transition)")
                return False, "REJECT"
        
        # Get transition
        new_state, write_symbol, direction = self.transitions[transition_key]
        
        # Write symbol
        self.tape[self.head_position] = write_symbol
        
        # Move head
        old_position = self.head_position
        if direction == 'R':
            self.head_position += 1
        elif direction == 'L':
            self.head_position -= 1
        # 'S' for stay
        
        # Update state
        old_state = self.current_state
        self.current_state = new_state
        self.step_count += 1
        
        # Record trace
        self._record_trace(f"δ({old_state}, {current_symbol}) → ({new_state}, {write_symbol}, {direction})")
        
        # Check if reached accept/reject state
        if self.current_state in self.accept_states:
            self._record_trace("ACCEPT")
            return False, "ACCEPT"
        elif self.current_state in self.reject_states:
            self._record_trace("REJECT")
            return False, "REJECT"
        
        return True, "RUNNING"
    
    def run(self, input_string):
        """Run the Turing Machine on input until completion"""
        self.load_input(input_string)
        
        while True:
            continue_running, status = self.step()
            if not continue_running:
                return status, self.trace
    
    def _record_trace(self, action):
        """Record current configuration in trace"""
        tape_str = ''.join(self.tape).replace(self.blank_symbol, '_')
        head_indicator = ' ' * self.head_position + '^'
        
        trace_entry = {
            'step': self.step_count,
            'state': self.current_state,
            'tape': tape_str,
            'head_position': self.head_position,
            'head_indicator': head_indicator,
            'action': action
        }
        self.trace.append(trace_entry)
    
    def get_tape_display(self):
        """Get formatted tape display"""
        return ''.join(self.tape).replace(self.blank_symbol, '_')


# Predefined Turing Machines

def create_binary_palindrome_checker():
    """
    Creates a Turing Machine that checks if a binary string is a palindrome.
    Complexity: Moderate
    
    Algorithm:
    1. Mark leftmost symbol and remember it
    2. Move to rightmost unmarked symbol
    3. Check if it matches the remembered symbol
    4. If match, mark it and return to left
    5. Repeat until all symbols checked
    6. Accept if all match, reject otherwise
    """
    states = {'q0', 'q1', 'q2', 'q3', 'q4', 'q5', 'q_accept', 'q_reject'}
    alphabet = {'0', '1', 'X', 'Y', '_'}
    blank = '_'
    initial = 'q0'
    accept = {'q_accept'}
    reject = {'q_reject'}
    
    transitions = {
        # Start: Mark first symbol
        ('q0', '0'): ('q1', 'X', 'R'),  # Mark 0, remember it, go right
        ('q0', '1'): ('q2', 'X', 'R'),  # Mark 1, remember it, go right
        ('q0', 'X'): ('q0', 'X', 'R'),  # Skip already marked
        ('q0', 'Y'): ('q0', 'Y', 'R'),  # Skip already marked
        ('q0', '_'): ('q_accept', '_', 'S'),  # Empty or all checked
        
        # q1: Remembered 0, moving right to find last unmarked
        ('q1', '0'): ('q1', '0', 'R'),
        ('q1', '1'): ('q1', '1', 'R'),
        ('q1', 'X'): ('q1', 'X', 'R'),
        ('q1', 'Y'): ('q1', 'Y', 'R'),
        ('q1', '_'): ('q3', '_', 'L'),  # Found end, go back to check
        
        # q2: Remembered 1, moving right to find last unmarked
        ('q2', '0'): ('q2', '0', 'R'),
        ('q2', '1'): ('q2', '1', 'R'),
        ('q2', 'X'): ('q2', 'X', 'R'),
        ('q2', 'Y'): ('q2', 'Y', 'R'),
        ('q2', '_'): ('q4', '_', 'L'),  # Found end, go back to check
        
        # q3: Check if last unmarked is 0 (matching remembered 0)
        ('q3', '0'): ('q5', 'Y', 'L'),  # Match! Mark and go back
        ('q3', '1'): ('q_reject', '1', 'S'),  # No match, reject
        ('q3', 'X'): ('q3', 'X', 'L'),  # Skip marked
        ('q3', 'Y'): ('q3', 'Y', 'L'),  # Skip marked
        
        # q4: Check if last unmarked is 1 (matching remembered 1)
        ('q4', '1'): ('q5', 'Y', 'L'),  # Match! Mark and go back
        ('q4', '0'): ('q_reject', '0', 'S'),  # No match, reject
        ('q4', 'X'): ('q4', 'X', 'L'),  # Skip marked
        ('q4', 'Y'): ('q4', 'Y', 'L'),  # Skip marked
        
        # q5: Move back to leftmost unmarked
        ('q5', '0'): ('q5', '0', 'L'),
        ('q5', '1'): ('q5', '1', 'L'),
        ('q5', 'Y'): ('q5', 'Y', 'L'),
        ('q5', 'X'): ('q0', 'X', 'R'),  # Found marked start, begin next iteration
    }
    
    return TuringMachine(states, alphabet, blank, initial, accept, reject, transitions)


def create_binary_increment():
    """
    Creates a Turing Machine that increments a binary number by 1.
    Complexity: Simple
    
    Example: 101 -> 110, 111 -> 1000
    """
    states = {'q0', 'q1', 'q_accept'}
    alphabet = {'0', '1', '_'}
    blank = '_'
    initial = 'q0'
    accept = {'q_accept'}
    reject = set()
    
    transitions = {
        # Move to rightmost digit
        ('q0', '0'): ('q0', '0', 'R'),
        ('q0', '1'): ('q0', '1', 'R'),
        ('q0', '_'): ('q1', '_', 'L'),  # Found end, start increment
        
        # Increment from right
        ('q1', '1'): ('q1', '0', 'L'),  # Carry over
        ('q1', '0'): ('q_accept', '1', 'S'),  # Done
        ('q1', '_'): ('q_accept', '1', 'S'),  # Overflow, add digit
    }
    
    return TuringMachine(states, alphabet, blank, initial, accept, reject, transitions)
