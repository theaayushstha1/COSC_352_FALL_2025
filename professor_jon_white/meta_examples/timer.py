"""
A simple decorator to measure and display method execution time.

This module provides a @time_execution decorator that can be applied to any
function or method to automatically measure how long it takes to run.
"""

import time
from functools import wraps


def time_execution(func):
    """
    A decorator that measures and prints the execution time of a function.
    
    This decorator wraps any function and calculates how long it takes to execute.
    It preserves the original function's name and docstring using functools.wraps.
    
    Args:
        func: The function to be timed
        
    Returns:
        A wrapper function that times the original function's execution
        
    Example:
        @time_execution
        def my_function():
            time.sleep(1)
            return "Done"
    """
    
    @wraps(func)  # Preserves the original function's metadata (name, docstring, etc.)
    def wrapper(*args, **kwargs):
        """
        The wrapper function that actually does the timing.
        
        Args:
            *args: Positional arguments to pass to the original function
            **kwargs: Keyword arguments to pass to the original function
            
        Returns:
            The result of the original function
        """
        
        # Record the start time before executing the function
        start_time = time.time()
        
        # Execute the original function and store its result
        # This allows us to return the result after timing
        result = func(*args, **kwargs)
        
        # Record the end time after the function completes
        end_time = time.time()
        
        # Calculate the elapsed time in seconds
        elapsed_time = end_time - start_time
        
        # Print the timing information
        # func.__name__ gives us the original function's name
        print(f"⏱️  '{func.__name__}' executed in {elapsed_time:.4f} seconds")
        
        # Return the original result so the decorator is transparent
        return result
    
    return wrapper


# ============================================================================
# EXAMPLE USAGE - STANDALONE FUNCTIONS
# ============================================================================

@time_execution
def fast_function():
    """A quick function that completes almost instantly."""
    return sum(range(1000))


@time_execution
def slow_function():
    """A slower function that takes about 1 second."""
    time.sleep(1)
    return "Processing complete"


@time_execution
def function_with_params(n, message="Hello"):
    """A function with parameters to show the decorator works with any signature."""
    time.sleep(0.5)
    return f"{message} - processed {n} items"


@time_execution
def calculate_sum(numbers):
    """Calculate the sum of a list of numbers."""
    total = 0
    for num in numbers:
        total += num
    time.sleep(0.2)  # Simulate some processing time
    return total


# ============================================================================
# DEMO CODE
# ============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("Function Execution Timer Demo")
    print("=" * 60)
    print()
    
    # Test the fast function
    print("Testing fast_function:")
    result1 = fast_function()
    print(f"Result: {result1}\n")
    
    # Test the slow function
    print("Testing slow_function:")
    result2 = slow_function()
    print(f"Result: {result2}\n")
    
    # Test function with parameters
    print("Testing function_with_params:")
    result3 = function_with_params(100, message="Success")
    print(f"Result: {result3}\n")
    
    # Test function with list parameter
    print("Testing calculate_sum:")
    result4 = calculate_sum([1, 2, 3, 4, 5, 10, 20, 30])
    print(f"Result: {result4}\n")
    
    print("=" * 60)