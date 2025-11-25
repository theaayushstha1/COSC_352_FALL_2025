# Baltimore Homicide Analysis - From Scala to Go

## What Does This Program Do?

This program reads Baltimore homicide data from a website and creates reports. You can get the results in three ways:
1. **CSV files** - Like Excel spreadsheets
2. **JSON files** - Data format for web applications
3. **Screen output** - Just prints the results to your terminal

## What Changed?

I rewrote the same program from **Scala** to **Go**. Both programs do the exact same thing, but they're written in different programming languages.

Think of it like translating a recipe from English to Spanish - the dish tastes the same, but the instructions are written differently!

## Simple Differences

### 1. **How You Write Variables**

**Scala** (the old way):
```scala
val name = "John"
val age = 30
```

**Go** (the new way):
```go
name := "John"
age := 30
```

### 2. **How You Store Data**

**Scala** uses "case classes":
```scala
case class Person(name: String, age: String)
```

**Go** uses "structs":
```go
type Person struct {
    Name string
    Age  string
}
```

### 3. **How You Loop Through Lists**

**Scala** (functional style):
```scala
people.filter(p => p.age > 18)
```

**Go** (explicit loop):
```go
for _, person := range people {
    if person.Age > 18 {
        // do something
    }
}
```

### 4. **How You Handle Errors**

**Scala** uses try-catch (like Java):
```scala
try {
    readFile()
} catch {
    case e: Exception => println("Error!")
}
```

**Go** checks errors immediately:
```go
data, err := readFile()
if err != nil {
    fmt.Println("Error!")
}
```

### 5. **File Sizes**

- **Scala version**: Docker image is about **300+ MB** (needs Java to run)
- **Go version**: Docker image is only **15 MB** (runs by itself!)



## What You Need to Run This

- **Docker** - A program that packages applications (like putting your program in a container)
- **Terminal/Command Line** - Where you type commands

## How to Run the Program

### Easy Way (Recommended)

```bash
# Step 1: Make the script runnable
chmod +x run_tables.sh

# Step 2: Run it!
./run_tables.sh --output=csv
```

That's it! Your files will be in the `output/` folder.

### Other Options

```bash
# Get JSON files instead
./run_tables.sh --output=json

# Just print to screen
./run_tables.sh

# See all options
./run_tables.sh --help
```

## What Files You'll Get

When you run the program with `--output=csv` or `--output=json`, you'll get these files in the `output/` folder:

1. `question1_stabbing_victims_2025.csv` - List of stabbing victims in 2025
2. `question2_east_baltimore_victims.csv` - List of victims in East Baltimore

## Why Go Instead of Scala?

### Go is Better For:
- **Smaller programs** - Takes up less space (15 MB vs 300 MB)
- **Faster startup** - Starts running immediately
- **Easier to share** - One file that runs anywhere
- **Uses less memory** - Doesn't need as much RAM

### Scala is Better For:
- **Shorter code** - Can write less to do the same thing
- **Functional style** - More mathematical way of thinking
- **Java libraries** - Can use existing Java code

## Both Programs Do the Same Thing!

No matter which version you run:
1. Reads homicide data from a website
2. Finds stabbing victims in 2025
3. Finds victims in East Baltimore
4. Creates reports in the format you choose

## Summary of Key Differences
Language Style:
Scala is a functional programming language that runs on Java, while Go is a simple, straightforward language that compiles directly to machine code. Scala lets you write in a more mathematical, abstract style, while Go is more direct and explicit about what it's doing.
Error Handling:
Scala uses try-catch blocks to handle errors, similar to Java. Go makes you check for errors immediately after every operation that might fail. This makes Go code more verbose but also makes it clearer when and where things might go wrong.
Processing Data:
Scala has built-in methods to filter and transform lists in one line, like asking "give me all items that match this condition." Go makes you write explicit loops to go through each item one by one and check conditions yourself.
File Size and Speed:
The Scala version needs Java to run, so the Docker container is over 300 megabytes. The Go version compiles to a standalone program that's only 15 megabytes - about 20 times smaller. Go also starts instantly, while Scala needs time to start up the Java virtual machine.
Code Length:
Scala typically requires fewer lines of code because it has more built-in shortcuts and can infer what you mean. Go is more explicit - you have to spell everything out, which makes the code longer but often easier to understand for beginners.
Dependencies:
Scala needs the entire Java runtime environment installed. Go compiles everything into one single file that runs by itself without needing anything else installed.
Writing Style:
Scala focuses on transforming data through chains of operations. Go focuses on step-by-step procedures with clear sequences of actions.
Deployment:
The Go version is much easier to deploy because it's just one small file. The Scala version needs Java installed wherever you want to run it, which adds complexity and size.
