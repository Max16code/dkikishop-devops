# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Production runtime (secure & lightweight)
FROM node:22-alpine
RUN apk add --no-cache dumb-init
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S -u 1001 -G nodejs appuser

COPY --from=builder --chown=appuser:nodejs /app/node_modules ./node_modules
COPY --chown=appuser:nodejs . .

USER appuser

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "server.js"]
