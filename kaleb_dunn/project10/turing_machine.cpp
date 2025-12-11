#include "turing_machine.h"
#include <algorithm>
#include <iomanip>

TuringMachine::TuringMachine(const std::string& initial, char blank, int max)
    : initial_state(initial), current_state(initial), blank_symbol(blank),
      head_position(0), max_steps(max), verbose(false) {
}

void TuringMachine::add_transition(const std::string& from_state, char read_symbol,
                                  const std::string& to_state, char write_symbol,
                                  char direction) {
    auto key = std::make_pair(from_state, read_symbol);
    transitions[key] = Transition(to_state, write_symbol, direction);
}

void TuringMachine::add_accept_state(const std::string& state) {
    accept_states.insert(state);
}

void TuringMachine::add_reject_state(const std::string& state) {
    reject_states.insert(state);
}

void TuringMachine::expand_tape_if_needed() {
    // Expand left
    while (head_position < 0) {
        tape.insert(tape.begin(), blank_symbol);
        head_position++;
    }
    
    // Expand right
    while (head_position >= static_cast<int>(tape.size())) {
        tape.push_back(blank_symbol);
    }
}

std::string TuringMachine::get_tape_string() const {
    std::string result;
    for (char c : tape) {
        result += c;
    }
    return result;
}

void TuringMachine::reset() {
    current_state = initial_state;
    tape.clear();
    head_position = 0;
    execution_trace.clear();
}

void TuringMachine::load_input(const std::string& input) {
    reset();
    
    if (input.empty()) {
        tape.push_back(blank_symbol);
    } else {
        for (char c : input) {
            tape.push_back(c);
        }
    }
}

bool TuringMachine::run(const std::string& input) {
    load_input(input);
    
    int step_count = 0;
    
    while (step_count < max_steps) {
        // Check if we're in accept or reject state
        if (accept_states.count(current_state)) {
            // Record final step
            Step final_step(step_count, current_state, get_tape_string(),
                          head_position, tape[head_position], tape[head_position],
                          'S', "ACCEPT");
            execution_trace.push_back(final_step);
            return true;
        }
        
        if (reject_states.count(current_state)) {
            // Record final step
            Step final_step(step_count, current_state, get_tape_string(),
                          head_position, tape[head_position], tape[head_position],
                          'S', "REJECT");
            execution_trace.push_back(final_step);
            return false;
        }
        
        // Expand tape if needed
        expand_tape_if_needed();
        
        // Read current symbol
        char current_symbol = tape[head_position];
        
        // Look up transition
        auto key = std::make_pair(current_state, current_symbol);
        
        if (transitions.find(key) == transitions.end()) {
            // No transition defined - implicit rejection
            Step final_step(step_count, current_state, get_tape_string(),
                          head_position, current_symbol, current_symbol,
                          'S', "NO TRANSITION (REJECT)");
            execution_trace.push_back(final_step);
            return false;
        }
        
        Transition& trans = transitions[key];
        
        // Record step before transition
        std::stringstream trans_desc;
        trans_desc << "δ(" << current_state << "," << current_symbol << ") → "
                   << "(" << trans.next_state << "," << trans.write_symbol
                   << "," << trans.direction << ")";
        
        Step step(step_count, current_state, get_tape_string(), head_position,
                 current_symbol, trans.write_symbol, trans.direction,
                 trans_desc.str());
        execution_trace.push_back(step);
        
        // Apply transition
        tape[head_position] = trans.write_symbol;
        current_state = trans.next_state;
        
        // Move head
        if (trans.direction == 'L') {
            head_position--;
        } else if (trans.direction == 'R') {
            head_position++;
        }
        // 'S' means stay
        
        step_count++;
    }
    
    // Max steps exceeded
    Step timeout_step(step_count, current_state, get_tape_string(),
                     head_position, tape[head_position], tape[head_position],
                     'S', "TIMEOUT (MAX STEPS EXCEEDED)");
    execution_trace.push_back(timeout_step);
    
    return false;
}

std::string TuringMachine::get_trace_string() const {
    std::stringstream ss;
    
    ss << "\n╔════════════════════════════════════════════════════════════════════╗\n";
    ss << "║                    TURING MACHINE EXECUTION TRACE                  ║\n";
    ss << "╚════════════════════════════════════════════════════════════════════╝\n\n";
    
    for (const auto& step : execution_trace) {
        ss << "Step " << std::setw(4) << step.step_number << ": "
           << "State: " << std::setw(10) << step.state << " | "
           << "Read: " << step.read_symbol << " → Write: " << step.write_symbol
           << " | Move: " << step.direction << "\n";
        
        // Show tape with head position
        ss << "           Tape: ";
        for (int i = 0; i < static_cast<int>(step.tape_content.length()); i++) {
            if (i == step.head_position) {
                ss << "[" << step.tape_content[i] << "]";
            } else {
                ss << " " << step.tape_content[i] << " ";
            }
        }
        ss << "\n";
        
        ss << "           " << step.transition << "\n\n";
    }
    
    return ss.str();
}

std::string TuringMachine::get_result_summary() const {
    if (execution_trace.empty()) {
        return "No execution trace available.";
    }
    
    const Step& final_step = execution_trace.back();
    
    std::stringstream ss;
    ss << "\n╔════════════════════════════════════════════════════════════════════╗\n";
    ss << "║                           RESULT SUMMARY                           ║\n";
    ss << "╚════════════════════════════════════════════════════════════════════╝\n\n";
    
    if (accept_states.count(final_step.state)) {
        ss << "✓ ACCEPTED\n\n";
    } else {
        ss << "✗ REJECTED\n\n";
    }
    
    ss << "Final State: " << final_step.state << "\n";
    ss << "Final Tape:  " << final_step.tape_content << "\n";
    ss << "Total Steps: " << execution_trace.size() << "\n";
    ss << "Reason:      " << final_step.transition << "\n\n";
    
    return ss.str();
}