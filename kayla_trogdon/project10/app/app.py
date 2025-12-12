"""
Turing Machine Simulator - Flask Web Application
Provides a web interface to test different Turing Machines
"""
from flask import Flask, render_template, request, jsonify
import sys
import os

#ADD CURRENT DIRECTORY TO PATH
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))

from machines.palindrome import create_palindrome_tm
from machines.binary_adder import create_binary_adder_tm
from machines.balanced_parens import create_balanced_parens_tm

app = Flask(__name__)

# Available Turing Machines
MACHINES = {
    'palindrome': {
        'name': 'Binary Palindrome Checker',
        'description': 'Checks if a binary string (0s and 1s) reads the same forwards and backwards',
        'examples': ['101', '1001', '111', '110'],
        'alphabet': '0, 1',
        'creator': create_palindrome_tm
    },
    'binary_adder': {
        'name': 'Binary Number Adder',
        'description': 'Adds 1 to a binary number (demonstrates carry propagation)',
        'examples': ['111', '1001', '101', '0'],
        'alphabet': '0, 1',
        'creator': create_binary_adder_tm
    },
    'balanced_parens': {
        'name': 'Balanced Parentheses Checker',
        'description': 'Checks if parentheses are properly balanced and nested',
        'examples': ['()', '(())', '()()', '(()'],
        'alphabet': '(, )',
        'creator': create_balanced_parens_tm
    }
}

@app.route('/')
def index(): 
    """Main page with TM selector and input form.""" 
    return render_template('index.html', machines=MACHINES)

@app.route('/simulate', methods=['POST'])
def simulate(): 
    """Runs a Turing Machine simukation.""" 
    data = request.get_json()

    machine_type = data.get('machine', 'palindrome')
    input_string = data.get('input', '')

    #Validate machine type
    if machine_type not in MACHINES: 
        return jsonify({
            'error': f'Unknown machine type: {machine_type}'
        }), 400
    
    #Create teh TM 
    tm = MACHINES[machine_type]['creator']()

    #Run the simulation
    try: 
        result = tm.run(input_string, max_steps=1000)
        return jsonify(result)
    except Exception as e:
        return jsonify({
            'error': f'Simulation error: {str(e)}'
        }), 500
@app.route('/health')
def health(): 
    """Health check endpoint."""
    return jsonify({'status': 'ok', 'machines': list(MACHINES.keys())})

if __name__ == '__main__':
    print("=" * 60)
    print("Turing Machine Simulator - Web Interface")
    print("=" * 60)
    print()
    print("Starting Flask server...")
    print("Visit: http://localhost:5000")
    print()
    print("Available machines:")
    for key, machine in MACHINES.items():
        print(f"  - {machine['name']}")
    print()
    print("Press Ctrl+C to stop")
    print("=" * 60)
    
    app.run(debug=True, host='0.0.0.0', port=5000)
