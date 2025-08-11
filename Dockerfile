# Multi-stage build for Node.js application
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY app/package*.json ./

# Install dependencies
RUN npm install --omit=dev

# Production stage
FROM node:18-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 nodejs && \
    adduser -S -u 1001 -G nodejs nodejs

# Copy from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs app/package*.json ./
COPY --chown=nodejs:nodejs app/src ./src

# Set build-time variables
ARG BUILD_TIME
ARG COMMIT_HASH
ARG VERSION=1.0.0

# Set environment variables
ENV NODE_ENV=production \
    APP_VERSION=${VERSION} \
    BUILD_TIME=${BUILD_TIME} \
    COMMIT_HASH=${COMMIT_HASH}

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {r.statusCode === 200 ? process.exit(0) : process.exit(1)})"

# Start application
CMD ["node", "src/index.js"]