package processor

import (
	"testing"
	"time"
)

func TestProcessBasic(t *testing.T) {
	it := Item{ID: 1, Payload: "hello world from go"}
	res := Process(it)
	if !res.OK {
		t.Fatalf("expected OK true, got false")
	}
	if res.WordCount != 4 {
		t.Fatalf("expected 4 words, got %d", res.WordCount)
	}
	if res.InputLen == 0 {
		t.Fatalf("expected non-zero input length")
	}
	// ensure processed timestamp is near now
	if time.Since(res.Processed) > time.Minute {
		t.Fatalf("processed timestamp seems wrong")
	}
}

func TestEmpty(t *testing.T) {
	it := Item{}
	res := Process(it)
	if res.OK {
		t.Fatalf("expected OK false for empty")
	}
}
