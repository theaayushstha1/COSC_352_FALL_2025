# i wanted to take an object oriented approach to this problem. 
'''
 the plan is to create two objects: 
 
 One that searches for and grabs data from tables.

 and another that writes said data to an csv file.
'''
from html.parser import HTMLParser
import urllib.request


'''
The html package is native to python,
so I can access it without doing any kind of extra isntilliation on my device.

from the html package's parser module (html.parser) I have imported the HtmlParser class 

urlib.request is a library in python's url package (also native: no instillation needed). 
we are going to use this to convert urls into parsible html.
'''

'''
rather than hard-coding the parsing logic, 
I leave that to HTMLParser's built in functionality.

in order to do this, I need to lay the instantiation of an HTMLParser object in my class that inherits from it.

so when my HTMLSCraper object is created, inside of it an HTMLParser object is created. 
'''

class HTMLScraper(HTMLParser):
    def __init__(self):
        super().__init__() # this line spins up an instance of the super-class (class being inherited from)

        '''
        the following attributes exist as...

        our flag to know whether we are inside a table header/data tag. (self.inside_td_or_th = false) 
        its set to false because before weve started we arent in any rows 
        
        a temporary container to extract the current row of data 
        '''
        self.inside_td_or_th = False
        self.current_row = []
        self.tables = []
        '''
        all of the methods operate on the aforementioned attributes.

        they all begin with a tag check and flip the flag to either True or False depending on what the scraper object is looking at.
        '''

    def handle_starttag(self, tag, attrs):
        # runs whenever a start tag like <td>, <th>, or <tr> appears
        if tag in ("td", "th"):
            self.inside_td_or_th = True
        elif tag == "tr":
            self.current_row = []

    def handle_endtag(self, tag):
        # runs whenever an end tag like </td>, </th>, or </tr> appears
        if tag in ("td", "th"):
            self.inside_td_or_th = False
        elif tag == "tr":
            if self.current_row:            # if this row has content => "if the list isnt empty"
                self.tables.append(self.current_row) # "add this to our self.tables spot to be turned into a csv down the line"

    '''
    in the following method we are inside of a table-header or the table-data, 
    and at this point we want to strip the text of its whitespaces
    and append it to the "current_row" list that we are in.
    '''
    def handle_data(self, data):
        # runs whenever text appears between tags
        if self.inside_td_or_th:
            text = data.strip()
            if text:
                self.current_row.append(text)
   

class CsvWriter:
    def __init__(self, filename):
        self.filename = filename

    def write_to_file(self, rows):
        '''
        Takes a list of lists (rows) and writes them to a CSV file.
        Each inner list becomes one line in the file, with values
        separated by commas.
        '''
        with open(self.filename, "w", encoding="utf-8") as outfile:
            for row in rows:
                outfile.write(",".join(row) + "\n")
        '''
        in this code snippet we are making use of python context manager "with" to close the file.
        weve opened up a file in "write-mode" (w) with utf-8 encoding.

        "rows" is our list of lists that weve extracted from the file.
        '''


'''
to run this code:

1. paste a url into the string variable named "url"
2. run the file in VS Code or the terminal
3. the output csv will be created in the same folder
'''


url = "https://en.wikipedia.org/wiki/Comparison_of_programming_languages"
# i encountered 403 error the first time i ran the code because my request for the webpage didnt meet the permissions
# the following line gets passed into the request because wikipedia now thinks im a browser.
headers = {"User-Agent": "Mozilla/5.0"}  

req = urllib.request.Request(url, headers=headers)
fetched_webpage = urllib.request.urlopen(req)
html_to_parse = fetched_webpage.read().decode("utf-8")

scraper = HTMLScraper()
scraper.feed(html_to_parse)

writer = CsvWriter("wiki_table_data.csv")
writer.write_to_file(scraper.tables)

print("First 5 rows:", scraper.tables[:5]) 
print("CSV file saved as wiki_table_data.csv")
