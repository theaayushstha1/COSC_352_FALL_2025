"""
Turing Machine simulator core implementation.
"""

from src.tape import Tape
from src.transition import TransitionFunction

class TuringMachine:
    """
    Turing Machine simulator that processes input strings.
    """
    
    def __init__(self, states, input_alphabet, tape_alphabet, transition_function,
                 start_state, accept_states, reject_states, blank_symbol='_'):
        """
        Initialize a Turing Machine.
        
        Args:
            states (set): Set of all states
            input_alphabet (set): Set of input symbols
            tape_alphabet (set): Set of tape symbols (includes input_alphabet)
            transition_function (TransitionFunction): Transition function
            start_state (str): Initial state
            accept_states (set): Set of accepting states
            reject_states (set): Set of rejecting states
            blank_symbol (str): Blank symbol
        """
        self.states = states
        self.input_alphabet = input_alphabet
        self.tape_alphabet = tape_alphabet
        self.transition_function = transition_function
        self.start_state = start_state
        self.accept_states = accept_states
        self.reject_states = reject_states
        self.blank_symbol = blank_symbol
        
        # Execution tracking
        self.current_state = start_state
        self.tape = None
        self.head_position = 0
        self.step_count = 0
        self.trace = []
        self.max_steps = 10000  # Prevent infinite loops
    
    def reset(self):
        """Reset the machine to initial state."""
        self.current_state = self.start_state
        self.head_position = 0
        self.step_count = 0
        self.trace = []
    
    def validate_input(self, input_string):
        """
        Validate that input string contains only symbols from input alphabet.
        
        Args:
            input_string (str): Input to validate
            
        Returns:
            bool: True if valid, False otherwise
        """
        return all(symbol in self.input_alphabet or symbol == self.blank_symbol 
                   for symbol in input_string)
    
    def run(self, input_string):
        """
        Run the Turing Machine on an input string.
        
        Args:
            input_string (str): Input string to process
            
        Returns:
            tuple: (accepted, trace) where accepted is bool and trace is list of steps
        """
        # Reset machine
        self.reset()
        
        # Validate input
        if not self.validate_input(input_string):
            return False, [{"error": "Invalid input: contains symbols not in input alphabet"}]
        
        # Initialize tape
        self.tape = Tape(input_string if input_string else self.blank_symbol, 
                        self.blank_symbol)
        
        # Record initial configuration
        self._record_step("INIT", self.blank_symbol, self.blank_symbol, "S")
        
        # Execute machine
        while (self.current_state not in self.accept_states and 
               self.current_state not in self.reject_states and
               self.step_count < self.max_steps):
            
            # Read current symbol
            current_symbol = self.tape.read(self.head_position)
            
            # Get transition
            transition = self.transition_function.get_transition(
                self.current_state, current_symbol
            )
            
            # If no transition defined, reject
            if transition is None:
                self.current_state = list(self.reject_states)[0]
                self._record_step("NO TRANSITION", current_symbol, current_symbol, "S")
                break
            
            next_state, write_symbol, direction = transition
            
            # Write symbol
            self.tape.write(self.head_position, write_symbol)
            
            # Record step before moving
            self._record_step(self.current_state, current_symbol, write_symbol, direction)
            
            # Move head
            if direction == 'R':
                self.head_position += 1
            elif direction == 'L':
                self.head_position -= 1
            # 'S' means stay
            
            # Update state
            self.current_state = next_state
            self.step_count += 1
        
        # Check if we hit max steps (infinite loop)
        if self.step_count >= self.max_steps:
            return False, self.trace + [{"error": "Maximum steps exceeded (possible infinite loop)"}]
        
        # Record final configuration
        self._record_step("HALT", self.tape.read(self.head_position), 
                         self.tape.read(self.head_position), "S")
        
        # Determine acceptance
        accepted = self.current_state in self.accept_states
        
        return accepted, self.trace
    
    def _record_step(self, state, read_symbol, write_symbol, direction):
        """
        Record a computation step in the trace.
        
        Args:
            state (str): Current state
            read_symbol (str): Symbol read
            write_symbol (str): Symbol written
            direction (str): Direction moved
        """
        step = {
            'step': self.step_count,
            'state': state,
            'head_position': self.head_position,
            'read_symbol': read_symbol,
            'write_symbol': write_symbol,
            'direction': direction,
            'tape': self.tape.get_tape_string(self.head_position) if self.tape else "",
            'tape_full': self.tape.get_full_tape() if self.tape else ""
        }
        self.trace.append(step)
    
    def get_result_explanation(self, accepted):
        """
        Generate human-readable explanation of the result.
        
        Args:
            accepted (bool): Whether input was accepted
            
        Returns:
            str: Explanation of result
        """
        if accepted:
            return f"✓ ACCEPTED: Input accepted in state '{self.current_state}' after {self.step_count} steps"
        else:
            return f"✗ REJECTED: Input rejected in state '{self.current_state}' after {self.step_count} steps"
    
    @classmethod
    def from_config(cls, config):
        """
        Create a Turing Machine from a configuration dictionary.
        
        Args:
            config (dict): Configuration dictionary
            
        Returns:
            TuringMachine: Configured Turing Machine instance
        """
        # Create transition function
        transition_function = TransitionFunction()
        transition_function.load_from_config(config)
        
        # Create and return TM
        return cls(
            states=set(config['states']),
            input_alphabet=set(config['input_alphabet']),
            tape_alphabet=set(config['tape_alphabet']),
            transition_function=transition_function,
            start_state=config['start_state'],
            accept_states=set(config['accept_states']),
            reject_states=set(config['reject_states']),
            blank_symbol=config.get('blank_symbol', '_')
        )