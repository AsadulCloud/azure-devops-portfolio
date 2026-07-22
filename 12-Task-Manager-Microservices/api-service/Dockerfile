FROM node:18-slim

WORKDIR /app

COPY package.json .
RUN npm install --omit=dev

COPY . .

EXPOSE 4000

CMD ["node", "app.js"]
