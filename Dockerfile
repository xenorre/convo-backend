# Multi-stage build for production
FROM node:20-alpine AS deps
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine AS development
WORKDIR /app
ENV NODE_ENV=development
COPY package*.json ./
RUN npm install
COPY . .

FROM node:20-alpine AS runner
WORKDIR /app
# Install tini and curl for proper signal handling and healthcheck
RUN apk add --no-cache tini curl
ENTRYPOINT ["/sbin/tini","--"]
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY src ./src
COPY package.json ./
# Non-root user for security
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD curl -fsS http://127.0.0.1:3000/healthz || exit 1
CMD ["node","src/index.js"]