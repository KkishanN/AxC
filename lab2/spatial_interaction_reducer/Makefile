CXX = clang++
CXXFLAGS = -O3 -std=c++17 -Wall -Wextra -Iinclude

TARGET = spatial_reducer_sim
SRCS = src/main.cpp

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all run clean
