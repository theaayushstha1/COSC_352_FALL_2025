#ifndef TURING_MACHINE_H
#define TURING_MACHINE_H

#include <string>
#include <map>
#include <vector>
#include <set>
#include <iostream>
#include <sstream>

/**
 * Transition structure for Turing Machine
 * Represents: (current_state, read_symbol) -> (next_state, write_symbol, direction)
 */
struct Transition {
    std::string next_state;
    char write_symbol;
    char direction;  // 'L' for left, 'R' for right, 'S' for stay
    
    Transition(const std::string& state, char write, char dir)
        : next_state(state), write_symbol(write), direction(dir) {}
    
    Transition() : next_state(""), write_symbol(' '), direction('S') {}
};

/**
 * Step trace for visualization
 */
struct Step {
    int step_number;
    std::string state;
    std::string tape_content;
    int head_position;
    char read_symbol;
    char write_symbol;
    char direction;
    std::string transition;
    
    Step(int num, const std::string& st, const std::string& tape, int pos,
         char read, char write, char dir, const std::string& trans)
        : step_number(num), state(st), tape_content(tape), head_position(pos),
          read_symbol(read), write_symbol(write), direction(dir), transition(trans) {}
};

/**
 * Turing Machine Simulator
 * Simulates a deterministic single-tape Turing Machine
 */
class TuringMachine {
private:
    std::string current_state;
    std::string initial_state;
    std::set<std::string> accept_states;
    std::set<std::string> reject_states;
    
    std::vector<char> tape;
    int head_position;
    char blank_symbol;
    
    // Transition function: (state, symbol) -> (new_state, write_symbol, direction)
    std::map<std::pair<std::string, char>, Transition> transitions;
    
    std::vector<Step> execution_trace;
    int max_steps;
    bool verbose;
    
    void expand_tape_if_needed();
    std::string get_tape_string() const;
    
public:
    TuringMachine(const std::string& initial, char blank = '_', int max = 10000);
    
    void add_transition(const std::string& from_state, char read_symbol,
                       const std::string& to_state, char write_symbol, char direction);
    
    void add_accept_state(const std::string& state);
    void add_reject_state(const std::string& state);
    
    bool run(const std::string& input);
    
    void set_verbose(bool v) { verbose = v; }
    
    const std::vector<Step>& get_trace() const { return execution_trace; }
    
    std::string get_trace_string() const;
    std::string get_result_summary() const;
    
    void reset();
    void load_input(const std::string& input);
};

#endif // TURING_MACHINE_H