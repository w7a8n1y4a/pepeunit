FROM --platform=$BUILDPLATFORM node:22-alpine as builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run docs:build

FROM nginx:alpine
EXPOSE 80

COPY --from=builder /app/docs/.vitepress/dist /usr/share/nginx/html
