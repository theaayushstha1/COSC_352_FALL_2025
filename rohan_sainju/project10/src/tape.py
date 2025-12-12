"""
Tape module for Turing Machine simulator.
Implements an infinite tape with a read/write head.
"""

class Tape:
    """
    Represents an infinite tape for a Turing Machine.
    The tape extends infinitely in both directions.
    """
    
    def __init__(self, input_string, blank_symbol='_'):
        """
        Initialize the tape with an input string.
        
        Args:
            input_string (str): Initial content for the tape
            blank_symbol (str): Symbol representing blank cells
        """
        self.blank_symbol = blank_symbol
        # Store tape as a dictionary for infinite extension
        self.tape = {}
        
        # Initialize tape with input string
        for i, symbol in enumerate(input_string):
            self.tape[i] = symbol
        
        # Track the leftmost and rightmost positions that have been written
        self.left_bound = 0
        self.right_bound = len(input_string) - 1 if input_string else 0
    
    def read(self, position):
        """
        Read symbol at given position.
        
        Args:
            position (int): Position to read from
            
        Returns:
            str: Symbol at position (blank if not written)
        """
        return self.tape.get(position, self.blank_symbol)
    
    def write(self, position, symbol):
        """
        Write symbol at given position.
        
        Args:
            position (int): Position to write to
            symbol (str): Symbol to write
        """
        self.tape[position] = symbol
        
        # Update bounds
        if position < self.left_bound:
            self.left_bound = position
        if position > self.right_bound:
            self.right_bound = position
    
    def get_tape_string(self, head_position, context=10):
        """
        Get a string representation of the tape around the head position.
        
        Args:
            head_position (int): Current head position
            context (int): Number of cells to show on each side
            
        Returns:
            str: String representation of tape
        """
        start = min(self.left_bound, head_position - context)
        end = max(self.right_bound, head_position + context)
        
        tape_str = ""
        for i in range(start, end + 1):
            tape_str += self.read(i)
        
        return tape_str
    
    def get_full_tape(self):
        """
        Get the full tape content from left bound to right bound.
        
        Returns:
            str: Full tape content
        """
        if not self.tape:
            return self.blank_symbol
        
        result = ""
        for i in range(self.left_bound, self.right_bound + 1):
            result += self.read(i)
        
        return result
    
    def get_head_offset(self, head_position, context=10):
        """
        Get the offset of the head in the displayed string.
        
        Args:
            head_position (int): Current head position
            context (int): Number of cells to show on each side
            
        Returns:
            int: Offset of head in displayed string
        """
        start = min(self.left_bound, head_position - context)
        return head_position - start