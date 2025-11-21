# Use official Haskell image
FROM haskell:latest

# Set working directory
WORKDIR /app

# Copy source code and CSV into container
COPY main.hs baltimore_homicides_combined.csv /app/


# Build the Haskell program
RUN ghc -o baltimore_analysis main.hs


# Run the program
CMD ["./baltimore_analysis"]
