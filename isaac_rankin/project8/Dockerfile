# Dockerfile for the Haskell Homicide Analysis tool

# Use the official Haskell/GHC image as the base
FROM haskell:9.6.3

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the Haskell source code and the data file into the container
# Ensure you copy your specific CSV filename
COPY Homicides.hs .
COPY baltimore_homicides_combined.csv .

# Compile the Haskell program
# -O2 for optimization, -o homicide-analysis for the output executable name
RUN ghc -O2 Homicides.hs -o homicide-analysis

# Define the command to run the application when the container starts
# This command executes the compiled binary
CMD ["./homicide-analysis"]