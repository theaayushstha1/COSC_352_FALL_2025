"""
Transition function module for Turing Machine simulator.
Defines state transitions based on current state and symbol.
"""

class TransitionFunction:
    """
    Represents the transition function (δ) of a Turing Machine.
    Maps (current_state, current_symbol) -> (next_state, write_symbol, direction)
    """
    
    def __init__(self):
        """Initialize empty transition function."""
        self.transitions = {}
    
    def add_transition(self, current_state, current_symbol, next_state, 
                       write_symbol, direction):
        """
        Add a transition rule to the function.
        
        Args:
            current_state (str): Current state
            current_symbol (str): Symbol currently under head
            next_state (str): State to transition to
            write_symbol (str): Symbol to write
            direction (str): Direction to move head ('L', 'R', or 'S' for stay)
        """
        key = (current_state, current_symbol)
        self.transitions[key] = (next_state, write_symbol, direction)
    
    def get_transition(self, current_state, current_symbol):
        """
        Get the transition for given state and symbol.
        
        Args:
            current_state (str): Current state
            current_symbol (str): Current symbol under head
            
        Returns:
            tuple: (next_state, write_symbol, direction) or None if no transition
        """
        key = (current_state, current_symbol)
        return self.transitions.get(key, None)
    
    def load_from_config(self, config):
        """
        Load transitions from configuration dictionary.
        
        Args:
            config (dict): Configuration with transitions
        """
        for transition in config.get('transitions', []):
            self.add_transition(
                transition['current_state'],
                transition['read_symbol'],
                transition['next_state'],
                transition['write_symbol'],
                transition['direction']
            )
    
    def __str__(self):
        """String representation of transition function."""
        result = "Transition Function:\n"
        for (state, symbol), (next_state, write_sym, direction) in sorted(self.transitions.items()):
            result += f"  δ({state}, {symbol}) = ({next_state}, {write_sym}, {direction})\n"
        return result