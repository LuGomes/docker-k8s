# Build Phase
FROM node:alpine as builder

WORKDIR /app

COPY package*.json ./
RUN npm install
COPY . .

RUN npm run build

# Run Phase
FROM nginx
# Elastic Beanstalk exposes this port
EXPOSE 80 
COPY --from=0 /app/build /usr/share/nginx/html

