APP=project6
BIN_DIR=bin
BIN=$(BIN_DIR)/$(APP)

.PHONY: build run clean

build:
	@mkdir -p $(BIN_DIR)
	GO111MODULE=on CGO_ENABLED=0 go build -o $(BIN) ./cmd/$(APP)

run: build
	./$(BIN) --input ./data/homicides.csv --year 2025 --question q1 --out text

clean:
	rm -rf $(BIN_DIR)
