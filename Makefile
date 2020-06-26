HUGO_PACKAGE ?= github.com/gohugoio/hugo@v0.73.0

build:
	docker run --rm -v "${PWD}":/usr/src/myapp -w /usr/src/myapp -e GO111MODULE=on golang:1.14-alpine sh -c "go get ${HUGO_PACKAGE} && hugo -D"
