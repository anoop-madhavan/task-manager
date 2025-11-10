FROM node:18-alpine

# Build arguments for version tracking
ARG REACT_APP_IMAGE_VERSION=latest
ARG BUILD_TIME=unknown

# Set as environment variables (React needs REACT_APP_ prefix)
ENV REACT_APP_IMAGE_VERSION=$REACT_APP_IMAGE_VERSION
ENV BUILD_TIME=$BUILD_TIME

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]

