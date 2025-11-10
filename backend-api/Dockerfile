FROM node:18-alpine

# Build arguments for version tracking
ARG IMAGE_VERSION=latest
ARG BUILD_TIME=unknown

# Set as environment variables
ENV IMAGE_VERSION=$IMAGE_VERSION
ENV BUILD_TIME=$BUILD_TIME

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3001

CMD ["npm", "run", "dev"]

