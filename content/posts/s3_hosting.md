---
title: "S3 hosting"
date: 2020-06-26T23:35:34+01:00
draft: false
---

I have chosen the following setup because of simplicity and cost (the only paid part is S3 and even this is quite minimal).

Setup consists of:
 - [hugo](#hugo) static website builder
 - [s3](#s3) hosting
 - [travis](#travis) ci/build
 - [cloudflare](#cloudflare) DNS, CDN, ...

## hugo

I wanted some simple framework that builds website/blog from
[markdown](https://daringfireball.net/projects/markdown/syntax) files. [Hugo](https://gohugo.io/) seems to be very
good option.

### build static pages
I use [makefile](https://github.com/reisinger/reisinger.co.uk/blob/master/Makefile) build target to generate static
pages:
```
HUGO_PACKAGE ?= github.com/gohugoio/hugo@v0.73.0

build:
	docker run --rm -v "${PWD}":/usr/src/myapp -w /usr/src/myapp -e GO111MODULE=on golang:1.14-alpine sh -c "go get ${HUGO_PACKAGE} && hugo"
``` 
this way user does not even need to have [hugo](https://gohugo.io/) framework installed. Simply add or edit
[markdown](https://daringfireball.net/projects/markdown/syntax) pages under
[content](https://github.com/reisinger/reisinger.co.uk/tree/master/content) directory and run `make build` to generate
`public` directory with static pages.

### test site locally
Changes can be tested locally with `make local-run` target:
```
HUGO_PACKAGE ?= github.com/gohugoio/hugo@v0.73.0

local-run:
	docker build --build-arg hugo_package=${HUGO_PACKAGE} -t reisinger/reisinger.co.uk:dev .
	docker run --rm --name reisinger.co.uk -p 8080:80 reisinger/reisinger.co.uk:dev
```

plus corresponding `Dockerfile`:
```
FROM golang:1.14-alpine AS build

WORKDIR /root
ARG hugo_package
RUN GO111MODULE=on go get $hugo_package
COPY . .
RUN sed -i 's/baseURL.*/baseURL = "http:\/\/localhost:8080\/"/' config.toml
RUN hugo -D

FROM nginx:1.19
COPY --from=build /root/public/ /usr/share/nginx/html
```

## s3

Create [s3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/create-bucket.html) with
"Block all public access" turned off.

Configure
[s3 bucket for static web hosting](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/static-website-hosting.html).
Select bucket and:
 - configure website hosting: `properties -> static website hosting -> use this bucket to host a website`. For index document
 select `index.html` and for error document select `404.html`.
 - enable public access (skip if you already done this when creating bucket):
 `permissions -> block public access -> edit -> "un-tick" Block all public access`
 - add bucket policy for cloudflare IP addresses: `permissions -> bucket policy`
 (replace `<bucket-name>` in `Resource` section):
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CloudflareReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::<bucket-name>/*",
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp": [
                        "2400:cb00::/32",
                        "2606:4700::/32",
                        "2803:f800::/32",
                        "2405:b500::/32",
                        "2405:8100::/32",
                        "2a06:98c0::/29",
                        "2c0f:f248::/32",
                        "173.245.48.0/20",
                        "103.21.244.0/22",
                        "103.22.200.0/22",
                        "103.31.4.0/22",
                        "141.101.64.0/18",
                        "108.162.192.0/18",
                        "190.93.240.0/20",
                        "188.114.96.0/20",
                        "197.234.240.0/22",
                        "198.41.128.0/17",
                        "162.158.0.0/15",
                        "104.16.0.0/12",
                        "172.64.0.0/13",
                        "131.0.72.0/22"
                    ]
                }
            }
        }
    ]
}
```
List of source IPs is taken from [cloudflare ip ranges](https://www.cloudflare.com/ips/) site.

## travis

[Travis](https://travis-ci.com/) runs `make build` and then pushes content of generated public directory to
[s3 bucket](https://aws.amazon.com/s3/). Content of
[.travis.yml](https://github.com/reisinger/reisinger.co.uk/blob/master/.travis.yml) file
(replace `<bucket-name>` and `<region>`):
```
language: minimal

git:
  depth: false
  quiet: true
  submodules: true

branches:
  only:
    - master

script:
  - "make build"

deploy:
  provider: s3
  access_key_id: $AWS_ACCESS_KEY
  secret_access_key: $AWS_SECRET_KEY
  bucket: <bucket-name>
  region: <region>
  skip_cleanup: true
  local_dir: ./public
  verbose: true
```

`git.submodules` is set to `true` so that hugo theme can be cloned as well. [Travis](https://travis-ci.com/) needs to be
configured with environment variables (`travis repository -> more options -> settings`) `AWS_ACCESS_KEY` and
`AWS_SECRET_KEY`.

Do NOT use root aws account credentials, but
[crate new AWS IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) with
"Programmatic access" instead and attach policy that only gives access to your bucket (replace `<bucket-name>`):
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObjectAcl",
                "s3:GetObject",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::<bucket-name>",
                "arn:aws:s3:::<bucket-name>/*"
            ]
        }
    ]
}
```

## cloudflare

[Create cloudflare account and add site](https://support.cloudflare.com/hc/en-us/articles/201720164-Creating-a-Cloudflare-account-and-adding-a-website).

Configure DNS and Page rules in [cloudflare](https://www.cloudflare.com/):
 - select site
 - under `DNS` tab, add two records:
   - `type: A, Name: www, Content: 192.0.2.1` (dummy record, this will be handled by page rule)
   - `type: CNAME, Name: <site-name>, Content: <bucket-name>.s3-website.<region>.amazonaws.com`
     (replace `<site-name>`, `<bucket-name>` and `<region>`)
 - under `SSL/TLS` tab select `flexible` encryption mode
 - under `Page Rules` create page rule for pattern `www.<site>/*` (replace `<site>`) with settings:
   - `Forwarding URL` -> `301 - Permanent Redirect`
   - `https://<site>/$1` (replace `<site>`)

It can take a bit of time to propagate all the DNS changes.
