# Non-root base image (runs as UID 101, listens on 8080)
FROM nginxinc/nginx-unprivileged:alpine
USER root
RUN apk upgrade --no-cache
USER 101
COPY app/index.html /usr/share/nginx/html/index.html
EXPOSE 8080
