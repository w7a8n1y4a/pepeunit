FROM node:18-alpine as builder

WORKDIR /app

COPY package*.json ./

RUN npm install
RUN npm add -D vitepress
RUN npm run docs:build

COPY . .

FROM nginx:alpine
EXPOSE 80

COPY --from=builder /app/docs/.vitepress/dist /usr/share/nginx/html
