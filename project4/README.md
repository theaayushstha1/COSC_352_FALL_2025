Project 4 - Baltimore Homicide Insights

Contents:
- `Main.scala` - Scala program that downloads the 2025 Baltimore homicide table and answers two questions.
- `Dockerfile` - Builds a container with sbt and runs the Scala program.
- `run.sh` - Builds the Docker image (if missing) and runs the container. No arguments.

Questions answered when running:
1) Top homicide hotspots (address blocks) in the dataset and sample victims at those blocks.
2) Whether homicides with surveillance cameras have higher closure rates compared to those without.

Usage:
chmod +x run.sh
./run.sh
