local-run: build
	docker build -t reisinger/reisinger.co.uk:dev .
	docker run --rm --name reisinger.co.uk -p 8080:80 reisinger/reisinger.co.uk:dev

build:
	docker run --rm -v "${PWD}":/usr/src/myapp -w /usr/src/myapp golang:1.23.4-alpine sh -c "go install github.com/gohugoio/hugo@v0.140.1 && hugo"
