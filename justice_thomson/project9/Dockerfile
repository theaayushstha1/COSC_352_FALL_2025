# -------------------------------------------------------
# 1. Base image with Python + system tools
# -------------------------------------------------------
FROM python:3.10-slim AS base

# Install system tools
RUN apt-get update && apt-get install -y curl bash git && apt-get clean

# -------------------------------------------------------
# 2. Install pixi (Mojo's package manager)
# -------------------------------------------------------
RUN curl -fsSL https://pixi.sh/install.sh | bash

# Add pixi to PATH (global install)
ENV PATH="/root/.pixi/bin:${PATH}"

# -------------------------------------------------------
# 3. Create Mojo project environment in WORKDIR
# -------------------------------------------------------
WORKDIR /app

# Initialize pixi project in current dir and add Mojo in one RUN to persist state
RUN pixi init . -c https://conda.modular.com/max-nightly/ -c conda-forge && \
    pixi add mojo

# Ensure pixi env PATH (for reference, but we'll use pixi run)
ENV PATH="/app/.pixi/envs/default/bin:${PATH}"

# -------------------------------------------------------
# 4. Install Python libs
# -------------------------------------------------------
RUN pip install pdfminer.six

# -------------------------------------------------------
# 5. Copy your Mojo program and PDF
# -------------------------------------------------------
COPY pdfsearch.mojo .
COPY morgan2030.pdf .

# -------------------------------------------------------
# 6. Build the Mojo program using pixi run
# -------------------------------------------------------
RUN pixi run mojo build pdfsearch.mojo -o pdfsearch

# -------------------------------------------------------
# 7. Default run command (you can override at runtime)
# -------------------------------------------------------
CMD ["./pdfsearch", "morgan2030.pdf", "R1 university", "3"]