FROM golang:1.14-alpine AS build

WORKDIR /root
RUN GO111MODULE=on go get github.com/gohugoio/hugo@v0.73.0
COPY . .
RUN hugo -D

FROM nginx:1.19
COPY --from=build /root/public/ /usr/share/nginx/html
