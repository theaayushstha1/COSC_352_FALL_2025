FROM haskell:9.2

WORKDIR /app

# Copy project files
COPY . .

# Install dependencies and build
RUN cabal update && cabal build

# Run the program
CMD ["cabal", "run", "project8"]