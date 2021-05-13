# reisinger.co.uk

[reisinger.co.uk](https://reisinger.co.uk) web built with [hugo](https://gohugo.io/) and hosted on
[S3](https://aws.amazon.com/s3/). With [cloudflare](https://www.cloudflare.com/) handling DNS, CDN ...

## initial setup

Project uses theme as git submodule, on initial clone you need to run:
- `git submodule init`
- `git submodule update`

## update/add

To update or add post, create/edit [markdown](https://daringfireball.net/projects/markdown/syntax) file under
[content](content) directory.

## test

To test changes locally, run `make local-run` and open [http://localhost:8080](http://localhost:8080) in the browser.

## deploy

`git commit` plus `git push` on a master branch, will automatically deploy changes using [.travis.yml](.travis.yml) file.
