# Stage 1: Build the application
FROM node:18 AS builder
WORKDIR /app
COPY package.json .
RUN npm install
COPY . .
RUN npm run build
# Stage 2: Production
FROM node:18-slim
WORKDIR /app
COPY package.json .
RUN npm install --omit=dev
COPY --from=builder /app/dist ./dist
EXPOSE 3000
CMD [ "node", "app.js" ]