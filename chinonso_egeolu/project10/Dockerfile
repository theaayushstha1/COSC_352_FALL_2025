FROM node:18-slim

WORKDIR /app

# Copy and install dependencies
COPY package.json ./
RUN npm install

# Copy all application files
COPY . .

# Expose web UI port (if web mode is used)
EXPOSE 3000

# Default to CLI mode
CMD ["node", "turing-machine.js"]