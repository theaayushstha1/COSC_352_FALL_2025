This project implements a command-line tool that:
	1.	Extracts text from the Morgan 2030 Strategic Plan PDF
	2.	Processes the extracted content
	3.	Searches for user-provided keywords
	4.	Returns the top N most relevant passages, including page number, a relevance score, and a text snippet

The project uses Python for PDF extraction and Mojo for the search tool logic.

How to Run

1. Navigate into the src directory
cd project9/src
2. Install the required Python package
pip install pypdf
3. Extract the PDF into a text file
python pdf_extract.py ../Morgan_2030.pdf ../pages.txt
4. Run the Mojo search tool
Note: Mojo may not run inside GitHub Codespaces.
mojo run search.mojo ../pages.txt "strategic goals" 5
This will output the top 5 most relevant matches, including:
	1. The page number
	2. Relevance score
	3. Text snippet that contains the search term
