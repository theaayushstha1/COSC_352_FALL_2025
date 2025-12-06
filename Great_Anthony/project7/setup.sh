#!/bin/bash
# Master setup script - runs all setup steps in order

echo "========================================="
echo "Baltimore Homicide Dashboard Setup"
echo "========================================="
echo ""

# Step 1: Install R and packages
echo "Step 1: Installing R and required packages..."
bash install_r.sh
if [ $? -ne 0 ]; then
    echo "Error: Installation failed. Please check error messages above."
    exit 1
fi
echo ""

# Step 2: Fetch data
echo "Step 2: Fetching homicide data..."
bash fetch_data.sh
if [ $? -ne 0 ]; then
    echo "Warning: Data fetch encountered issues. You may need to download data manually."
fi
echo ""

# Step 3: Instructions for running
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "To run the dashboard:"
echo "  Rscript run_app.R"
echo ""
echo "Or with Docker:"
echo "  docker build -t baltimore-homicide-dashboard ."
echo "  docker run -p 3838:3838 baltimore-homicide-dashboard"
echo ""
echo "Then open your browser to: http://localhost:3838"
echo ""
