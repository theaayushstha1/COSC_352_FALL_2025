package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"sync"

	"github.com/yourusername/project5-go/processor"
)

func usage() {
	fmt.Fprintf(os.Stderr, "Usage: %s -input input.json -workers 4\n", os.Args[0])
	flag.PrintDefaults()
}

func main() {
	inputPath := flag.String("input", "", "Path to input JSON file (array). Use '-' for stdin.")
	workers := flag.Int("workers", 4, "Number of concurrent workers")
	flag.Usage = usage
	flag.Parse()

	var r io.Reader
	if *inputPath == "" || *inputPath == "-" {
		r = os.Stdin
	} else {
		f, err := os.Open(*inputPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error opening input: %v\n", err)
			os.Exit(2)
		}
		defer f.Close()
		r = f
	}

	// Expect input to be JSON array of objects: [{"id":1,"payload":"..."} , ...]
	var items []processor.Item
	dec := json.NewDecoder(r)
	if err := dec.Decode(&items); err != nil {
		fmt.Fprintf(os.Stderr, "error decoding input JSON: %v\n", err)
		os.Exit(3)
	}

	results := make([]processor.Result, len(items))

	// Worker pool
	jobs := make(chan processor.Job)
	var wg sync.WaitGroup

	for i := 0; i < *workers; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			for job := range jobs {
				res := processor.Process(job.Item)
				results[job.Index] = res
			}
		}(i)
	}

	// send jobs
	for i, it := range items {
		jobs <- processor.Job{Index: i, Item: it}
	}
	close(jobs)
	wg.Wait()

	// output as JSON
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	if err := enc.Encode(results); err != nil {
		fmt.Fprintf(os.Stderr, "error encoding results: %v\n", err)
		os.Exit(4)
	}
}
