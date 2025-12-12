FROM haskell:9.4

WORKDIR /app

# Copy source files
COPY Main.hs .
COPY baltimore_homicides_combined.csv .

# Install dependencies and build
RUN cabal update && \
    cabal install --lib cassava vector bytestring containers && \
    ghc -O2 -o homicide-analyzer Main.hs

# Run the program
CMD ["./homicide-analyzer"]