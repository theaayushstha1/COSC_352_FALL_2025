# -------------------------------------------------------
# 1. Base image
# -------------------------------------------------------
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required system tools
RUN apt-get update && apt-get install -y \
    curl \
    bash \
    git \
    wget \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------
# 2. Install pixi
# -------------------------------------------------------
RUN curl -fsSL https://pixi.sh/install.sh | bash
ENV PATH="/root/.pixi/bin:${PATH}"

# -------------------------------------------------------
# 3. Set up working directory
# -------------------------------------------------------
WORKDIR /app

# -------------------------------------------------------
# 4. Copy pixi config first (for better caching)
# -------------------------------------------------------
COPY pixi.toml pixi.lock* ./

# -------------------------------------------------------
# 5. Install all dependencies via pixi
#    Your pixi.toml already has mojo from max-nightly channel
#    and pypdf2, so this installs everything!
# -------------------------------------------------------
RUN pixi install

# -------------------------------------------------------
# 6. Copy project files
# -------------------------------------------------------
COPY pdfsearch.mojo ./
COPY morgan2030.pdf ./

# -------------------------------------------------------
# 7. Default command - run the search via pixi
# -------------------------------------------------------
CMD ["pixi", "run", "mojo", "pdfsearch.mojo", "morgan2030.pdf", "R1 university", "3"]