FROM nginx:1.27.3
COPY public /usr/share/nginx/html
RUN grep -rl 'https:\/\/reisinger\.co\.uk\/' /usr/share/nginx/html | xargs sed -i 's/https:\/\/reisinger\.co\.uk\//http:\/\/localhost:8080\//g'
