const express = require('express');
const path = require('path');
const {
    createBinaryPalindromeChecker,
    createBalancedParenthesesChecker,
    createAnBnChecker
} = require('./turing-machine');

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.static('public'));

// API endpoint to run Turing Machine
app.post('/api/run', (req, res) => {
    const { machine, input } = req.body;
    
    let tm;
    switch (machine) {
        case 'palindrome':
            tm = createBinaryPalindromeChecker();
            break;
        case 'parentheses':
            tm = createBalancedParenthesesChecker();
            break;
        case 'anbn':
            tm = createAnBnChecker();
            break;
        default:
            return res.status(400).json({ error: 'Invalid machine type' });
    }
    
    const result = tm.run(input);
    res.json(result);
});

app.listen(PORT, () => {
    console.log(`Turing Machine Web UI running at http://localhost:${PORT}`);
});