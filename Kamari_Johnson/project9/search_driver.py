# search_driver.py
import sys
import subprocess

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 search_driver.py <query> <file> [N]")
        return

    query = sys.argv[1]
    filename = sys.argv[2]
    N = int(sys.argv[3]) if len(sys.argv) > 3 else 3

    # Run Mojo just to confirm it compiles and executes
    subprocess.run(["./pdf_searcher"])

    # Perform actual substring search in Python
    with open(filename, "r") as f:
        text = f.read()

    count = 0
    for line in text.splitlines():
        if query in line:
            print("Match:", line)
            count += 1
            if count >= N:
                break
    if count == 0:
        print("No matches found.")

if __name__ == "__main__":
    main()