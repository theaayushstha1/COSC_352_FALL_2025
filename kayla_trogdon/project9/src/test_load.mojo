from python import Python, PythonObject

fn main() raises:
    print("Testing JSON loading...")
    
    var py = Python.import_module("builtins")
    var json = Python.import_module("json")
    
    print("Step 1: Modules imported ✓")
    
    var filepath = "data/passages.json"
    print("Step 2: Filepath:", filepath)
    
    print("Step 3: Opening file...")
    var file = py.open(filepath, "r")
    
    print("Step 4: Reading file...")
    var content = file.read()
    
    print("Step 5: Closing file...")
    file.close()
    
    print("Step 6: Parsing JSON...")
    var data = json.loads(content)
    
    print("Step 7: Getting passages...")
    var passages = data["passages"]
    
    print("Step 8: Counting passages...")
    var total = passages.__len__()
    
    print("✅ Success! Loaded", total, "passages")