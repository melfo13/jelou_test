FROM node:18-alpine

# Ensuring not using root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Handle dependencies first
COPY package*.json ./

# Install prod dependencies only
RUN npm ci --only=production && \
    npm cache clean --force

# Get the application code
COPY --chown=nodejs:nodejs . .

USER nodejs

EXPOSE 3000

CMD ["/usr/local/bin/node", "app.js"]