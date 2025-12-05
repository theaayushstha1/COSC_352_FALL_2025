## 1. Mojo Installation
**Option 2** (Using Mojo Programming Language) (mojo_search.mojo)
- Install Magic package manager
curl -ssL https://magic.modular.com | bash

- Restart your terminal or run:
source ~/.bashrc  # or ~/.zshrc for zsh

- Verify installation
magic --version

- Initialize a Mojo project
magic init pdf-search --format mojoproject
cd pdf-search

- Install MAX (includes Mojo)
magic add max

## 2. Install dependencies
pip install pypdf

## 3. Running the Program
```bash
# Navigate to file location clyde_baidoo/project9/mojo_search.mojo

# Make the file executable 
chmod +x mojo_search.mojo

# In the terminal, run;
mojo mojo_search.mojo <pdf_file> "<query>" <num_results>

# Examples:
mojo mojo_search.mojo morgan.pdf "The bold vision animating our Transformation" 5

Sample Output
Extracting text from PDF...
Indexing 40 passages...
Calculating IDF scores...
Ranking passages by relevance...

Results for: "The bold vision animating our Transformation"
======================================================================

[1] Score: 0.85 (page 26)
    "Human resource planning is essential to the implementation of this  strategic plan and will profoundly influence the achievement of its  stated objectives. At Morgan State University, our faculty r..."

[2] Score: 0.79 (page 11)
    "FUTURE… Carrying  Our Vision  and Values  into the LEADING THE FUTURE 11 MORGAN.EDU"

[3] Score: 0.64 (page 2)
    "2030 Transformation MORGAN LEADING THE FUTURE T able of Contents  3 Institutional Profile  4 A Message From the  President  6 Vision Statement  7 Our Mission  8 Our Core Values  12 Strategic Planni..."

[4] Score: 0.54 (page 34)
    "The University’s Division of International Affairs has articulated a bold  vision to bring to fruition MORGAN GLOBAL over the next ten years.  This ambitious initiative will unfold over the next te..."

[5] Score: 0.48 (page 5)
    "A SEARCH FOR SOLUTIONS TO SOCIETY’S  MOST PRESSING CHALLENGES Today, our sprawling campus provides indisputable  evidence of a thriving living-learning environment  populated by students, faculty a..."
```





