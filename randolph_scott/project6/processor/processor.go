package processor

import (
	"errors"
	"strings"
	"time"
)

// Item is the input struct. Adjust fields to match your Scala project's DTOs.
type Item struct {
	ID      int    `json:"id"`
	Payload string `json:"payload"`
}

// Result is the processed output.
type Result struct {
	ID        int       `json:"id"`
	InputLen  int       `json:"input_len"`
	WordCount int       `json:"word_count"`
	OK        bool      `json:"ok"`
	Processed time.Time `json:"processed"`
	Note      string    `json:"note,omitempty"`
}

// Job couples an item with its index so we can retain ordering.
type Job struct {
	Index int
	Item  Item
}

// Process performs the "work" on a single Item. Replace with your actual logic.
func Process(it Item) Result {
	if it.ID == 0 && strings.TrimSpace(it.Payload) == "" {
		return Result{
			ID:        it.ID,
			InputLen:  0,
			WordCount: 0,
			OK:        false,
			Processed: time.Now().UTC(),
			Note:      "empty item",
		}
	}

	if len(it.Payload) > 10_000_000 {
		// Example of error handling/policy
		return Result{
			ID:        it.ID,
			InputLen:  len(it.Payload),
			WordCount: 0,
			OK:        false,
			Processed: time.Now().UTC(),
			Note:      "payload too large",
		}
	}

	words := splitWords(it.Payload)
	return Result{
		ID:        it.ID,
		InputLen:  len(it.Payload),
		WordCount: len(words),
		OK:        true,
		Processed: time.Now().UTC(),
	}
}

// splitWords is a tiny helper to demonstrate text processing.
func splitWords(s string) []string {
	s = strings.TrimSpace(s)
	if s == "" {
		return []string{}
	}
	// Very simple split; adapt to language/tokenization needs.
	return strings.Fields(s)
}

// Example of a function that might return an error (not used above).
func MaybeErrorExample(x int) (int, error) {
	if x < 0 {
		return 0, errors.New("negative not allowed")
	}
	return x * 2, nil
}
