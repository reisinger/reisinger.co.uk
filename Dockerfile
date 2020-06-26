FROM golang:1.14-alpine AS build

WORKDIR /root
ARG hugo_package
RUN GO111MODULE=on go get $hugo_package
COPY . .
RUN sed -i 's/baseURL.*/baseURL = "http:\/\/localhost:8080\/"/' config.toml
RUN hugo -D

FROM nginx:1.19
COPY --from=build /root/public/ /usr/share/nginx/html