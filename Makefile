HUGO_PACKAGE ?= github.com/gohugoio/hugo@v0.73.0

local-run:
	docker build --build-arg hugo_package=${HUGO_PACKAGE} -t reisinger/reisinger.co.uk:dev .
	docker run --rm --name reisinger.co.uk -p 8080:80 reisinger/reisinger.co.uk:dev

build:
	docker run --rm -v "${PWD}":/usr/src/myapp -w /usr/src/myapp -e GO111MODULE=on golang:1.14-alpine sh -c "go get ${HUGO_PACKAGE} && hugo"

