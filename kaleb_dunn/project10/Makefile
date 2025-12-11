CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O2
TARGET = turing_machine
OBJS = main.o turing_machine.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(OBJS)

main.o: main.cpp turing_machine.h examples.cpp
	$(CXX) $(CXXFLAGS) -c main.cpp

turing_machine.o: turing_machine.cpp turing_machine.h
	$(CXX) $(CXXFLAGS) -c turing_machine.cpp

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean