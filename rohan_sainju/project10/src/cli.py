"""
Command-line interface for Turing Machine simulator.
"""

import json
import sys
from tabulate import tabulate
from colorama import init, Fore, Style
from src.turing_machine import TuringMachine

# Initialize colorama
init(autoreset=True)

class CLI:
    """Command-line interface for the Turing Machine simulator."""
    
    def __init__(self):
        """Initialize CLI."""
        self.tm = None
        self.config_name = None
    
    def load_machine(self, config_path):
        """
        Load a Turing Machine from a configuration file.
        
        Args:
            config_path (str): Path to configuration JSON file
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
            
            self.tm = TuringMachine.from_config(config)
            self.config_name = config.get('name', 'Unknown')
            
            print(f"{Fore.GREEN}✓ Loaded Turing Machine: {self.config_name}")
            print(f"{Fore.CYAN}Description: {config.get('description', 'No description')}\n")
            
            return True
        except FileNotFoundError:
            print(f"{Fore.RED}✗ Error: Configuration file '{config_path}' not found")
            return False
        except json.JSONDecodeError as e:
            print(f"{Fore.RED}✗ Error: Invalid JSON in configuration file: {e}")
            return False
        except Exception as e:
            print(f"{Fore.RED}✗ Error loading machine: {e}")
            return False
    
    def run_input(self, input_string):
        """
        Run the Turing Machine on an input string.
        
        Args:
            input_string (str): Input string to process
        """
        if self.tm is None:
            print(f"{Fore.RED}✗ No Turing Machine loaded. Use --config to load one.")
            return
        
        print(f"\n{Fore.CYAN}{'='*80}")
        print(f"{Fore.CYAN}Running Turing Machine: {self.config_name}")
        print(f"{Fore.CYAN}Input: '{input_string}' (length: {len(input_string)})")
        print(f"{Fore.CYAN}{'='*80}\n")
        
        # Run the machine
        accepted, trace = self.tm.run(input_string)
        
        # Check for errors
        if trace and 'error' in trace[0]:
            print(f"{Fore.RED}✗ {trace[0]['error']}\n")
            return
        
        # Display trace
        self._display_trace(trace)
        
        # Display result
        print(f"\n{Fore.CYAN}{'='*80}")
        result_explanation = self.tm.get_result_explanation(accepted)
        if accepted:
            print(f"{Fore.GREEN}{result_explanation}")
        else:
            print(f"{Fore.RED}{result_explanation}")
        print(f"{Fore.CYAN}{'='*80}\n")
        
        # Display evaluation
        self._display_evaluation(input_string, accepted, trace)
    
    def _display_trace(self, trace):
        """
        Display the computation trace in a formatted table.
        
        Args:
            trace (list): List of computation steps
        """
        print(f"{Fore.YELLOW}Computation Trace:")
        print(f"{Fore.YELLOW}{'-'*80}\n")
        
        # Prepare table data
        headers = ["Step", "State", "Read", "Write", "Move", "Head Pos", "Tape"]
        rows = []
        
        for step in trace:
            # Create visual tape with head indicator
            tape_str = step['tape']
            head_offset = step['head_position']
            
            # For display, we'll show the tape and indicate head position below
            rows.append([
                step['step'],
                step['state'],
                step['read_symbol'],
                step['write_symbol'],
                step['direction'],
                step['head_position'],
                tape_str
            ])
        
        # Print table
        print(tabulate(rows, headers=headers, tablefmt="grid"))
        print()
    
    def _display_evaluation(self, input_string, accepted, trace):
        """
        Display detailed evaluation of how the decision was made.
        
        Args:
            input_string (str): Original input
            accepted (bool): Whether input was accepted
            trace (list): Computation trace
        """
        print(f"{Fore.YELLOW}Evaluation Details:")
        print(f"{Fore.YELLOW}{'-'*80}\n")
        
        print(f"Input String: '{input_string}'")
        print(f"Input Length: {len(input_string)}")
        print(f"Total Steps: {len(trace) - 2}")  # Exclude INIT and HALT
        print(f"Final State: {trace[-1]['state']}")
        print(f"Final Tape: {trace[-1]['tape_full']}")
        print()
        
        if accepted:
            print(f"{Fore.GREEN}Decision: ACCEPTED ✓")
            print(f"{Fore.GREEN}Reason: The Turing Machine reached an accept state.")
        else:
            print(f"{Fore.RED}Decision: REJECTED ✗")
            print(f"{Fore.RED}Reason: The Turing Machine reached a reject state or no valid transition was found.")
        print()
    
    def interactive_mode(self):
        """Run the CLI in interactive mode."""
        if self.tm is None:
            print(f"{Fore.RED}✗ No Turing Machine loaded. Use --config to load one.")
            return
        
        print(f"\n{Fore.CYAN}{'='*80}")
        print(f"{Fore.CYAN}Interactive Mode - Turing Machine: {self.config_name}")
        print(f"{Fore.CYAN}{'='*80}\n")
        print(f"{Fore.YELLOW}Enter input strings to test (or 'quit' to exit):\n")
        
        while True:
            try:
                user_input = input(f"{Fore.GREEN}Input> {Style.RESET_ALL}").strip()
                
                if user_input.lower() in ['quit', 'exit', 'q']:
                    print(f"\n{Fore.CYAN}Goodbye!")
                    break
                
                if user_input == '':
                    user_input = self.tm.blank_symbol
                
                self.run_input(user_input)
                
            except KeyboardInterrupt:
                print(f"\n\n{Fore.CYAN}Goodbye!")
                break
            except EOFError:
                break

def main():
    """Main entry point for CLI."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Turing Machine Simulator',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run with specific input
  python -m src.cli --config examples/palindrome_config.json --input "0110"
  
  # Interactive mode
  python -m src.cli --config examples/palindrome_config.json --interactive
  
  # Run test cases from file
  python -m src.cli --config examples/palindrome_config.json --test-file tests/test_cases.txt
        """
    )
    
    parser.add_argument('--config', '-c', required=True,
                       help='Path to Turing Machine configuration JSON file')
    parser.add_argument('--input', '-i',
                       help='Input string to process')
    parser.add_argument('--interactive', '-int', action='store_true',
                       help='Run in interactive mode')
    parser.add_argument('--test-file', '-t',
                       help='File containing test cases (one per line)')
    
    args = parser.parse_args()
    
    # Create CLI instance
    cli = CLI()
    
    # Load machine
    if not cli.load_machine(args.config):
        sys.exit(1)
    
    # Process based on mode
    if args.interactive:
        cli.interactive_mode()
    elif args.test_file:
        try:
            with open(args.test_file, 'r') as f:
                for line_num, line in enumerate(f, 1):
                    line = line.strip()
                    if line and not line.startswith('#'):
                        print(f"\n{Fore.MAGENTA}{'='*80}")
                        print(f"{Fore.MAGENTA}Test Case {line_num}: '{line}'")
                        print(f"{Fore.MAGENTA}{'='*80}")
                        cli.run_input(line)
        except FileNotFoundError:
            print(f"{Fore.RED}✗ Test file '{args.test_file}' not found")
            sys.exit(1)
    elif args.input is not None:
        cli.run_input(args.input)
    else:
        print(f"{Fore.RED}✗ Please specify --input, --interactive, or --test-file")
        parser.print_help()
        sys.exit(1)

if __name__ == '__main__':
    main()