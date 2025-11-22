FROM haskell:9.4

WORKDIR /app

# Copy source code and CSV
COPY HomicideAnalyzer.hs .
COPY baltimore_homicides_combined.csv .

# Compile the Haskell program
RUN ghc -o analyzer HomicideAnalyzer.hs

# Run the analyzer
CMD ["./analyzer"]