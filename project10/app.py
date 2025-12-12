"""
Flask Web Application for Turing Machine Simulator
Provides a user-friendly web interface to interact with the TM
"""

from flask import Flask, render_template, request, jsonify
from turing_machine import (
    TuringMachine, 
    create_binary_palindrome_tm,
    create_balanced_parentheses_tm
)

app = Flask(__name__)

# Store available Turing Machines
MACHINES = {
    'binary_palindrome': {
        'name': 'Binary Palindrome Recognizer',
        'description': 'Recognizes strings that are palindromes in binary (0s and 1s)',
        'alphabet': '{0, 1}',
        'examples': {
            'valid': ['101', '1001', '0', '11011', '10101', '111', '000'],
            'invalid': ['10', '110', '0110', '1000', '10110']
        },
        'complexity': 'O(n²) time, O(n) space',
        'creator': create_binary_palindrome_tm
    },
    'balanced_parentheses': {
        'name': 'Balanced Parentheses Checker',
        'description': 'Recognizes strings with balanced parentheses',
        'alphabet': '{(, )}',
        'examples': {
            'valid': ['()', '(())', '()()', '((()))', '(()())'],
            'invalid': ['(', ')', '(()', '())', '(()))']
        },
        'complexity': 'O(n²) time, O(n) space',
        'creator': create_balanced_parentheses_tm
    }
}

@app.route('/')
def index():
    """Main page"""
    return render_template('index.html', machines=MACHINES)

@app.route('/api/run', methods=['POST'])
def run_machine():
    """API endpoint to run a Turing Machine"""
    data = request.get_json()
    
    machine_type = data.get('machine', 'binary_palindrome')
    input_string = data.get('input', '')
    
    if machine_type not in MACHINES:
        return jsonify({'error': 'Invalid machine type'}), 400
    
    # Create the Turing Machine
    tm = MACHINES[machine_type]['creator']()
    
    # Run it
    accepted, trace = tm.run(input_string)
    
    # Format response
    response = {
        'accepted': accepted,
        'result': 'ACCEPTED ✓' if accepted else 'REJECTED ✗',
        'steps': len(trace),
        'trace': trace,
        'formatted_trace': tm.format_trace()
    }
    
    return jsonify(response)

@app.route('/api/machines')
def list_machines():
    """List available Turing Machines"""
    machines_info = {}
    for key, info in MACHINES.items():
        machines_info[key] = {
            'name': info['name'],
            'description': info['description'],
            'alphabet': info['alphabet'],
            'examples': info['examples'],
            'complexity': info['complexity']
        }
    return jsonify(machines_info)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
