"""
Flask Web Application for Turing Machine Simulator
Author: Aayush Shrestha
Morgan State University
"""

from flask import Flask, render_template, request, jsonify
from turing_machine import create_binary_palindrome_checker, create_binary_increment

app = Flask(__name__)

# Turing Machine configurations (functions stored separately)
TM_CREATORS = {
    'palindrome': create_binary_palindrome_checker,
    'increment': create_binary_increment
}

# Machine metadata (for display only - no functions)
TM_MACHINES = {
    'palindrome': {
        'name': 'Binary Palindrome Checker',
        'description': 'Checks if a binary string reads the same forwards and backwards',
        'example_accept': ['0', '1', '00', '11', '010', '101', '0110', '1001'],
        'example_reject': ['01', '10', '001', '110', '0111']
    },
    'increment': {
        'name': 'Binary Increment',
        'description': 'Increments a binary number by 1',
        'example_accept': ['0', '1', '10', '101', '111'],
        'example_reject': []
    }
}

@app.route('/')
def index():
    return render_template('index.html', machines=TM_MACHINES)

@app.route('/run', methods=['POST'])
def run_turing_machine():
    """Run the selected Turing Machine on input"""
    data = request.json
    machine_type = data.get('machine', 'palindrome')
    input_string = data.get('input', '')
    
    if machine_type not in TM_CREATORS:
        return jsonify({'error': 'Invalid machine type'}), 400
    
    # Create TM using the creator function
    tm = TM_CREATORS[machine_type]()
    
    try:
        result, trace = tm.run(input_string)
        
        return jsonify({
            'result': result,
            'trace': trace,
            'steps': len(trace) - 1,
            'passed': result == 'ACCEPT'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
