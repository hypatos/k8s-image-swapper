FROM golang:1.22 AS builder


WORKDIR /app
COPY . .
RUN apt update && apt-get install libbtrfs-dev -y
RUN go mod download
RUN go mod tidy
RUN GOARCH=amd64 CGO_ENABLED=0 go build -o k8s-image-swapper

# TODO: Using alpine for now due to easier installation of skopeo
#       Will use distroless after incorporating skopeo into the webhook directly
FROM alpine:3.21.2
RUN ["apk", "add", "--no-cache", "--repository=http://dl-cdn.alpinelinux.org/alpine/edge/community", "skopeo>=1.2.0", "file"]
RUN mkdir /app
COPY --from=builder /app/k8s-image-swapper /app/k8s-image-swapper
RUN ls -latr /app/*
RUN file /app/k8s-image-swapper

RUN chmod +x /app/k8s-image-swapper

ENTRYPOINT ["/app/k8s-image-swapper"]

ARG BUILD_DATE
ARG VCS_REF

LABEL maintainer="k8s-image-swapper <https://github.com/estahn/k8s-image-swapper/issues>" \
      org.opencontainers.image.title="k8s-image-swapper" \
      org.opencontainers.image.description="Mirror images into your own registry and swap image references automatically." \
      org.opencontainers.image.url="https://github.com/estahn/k8s-image-swapper" \
      org.opencontainers.image.source="https://github.com/estahn/k8s-image-swapper" \
      org.opencontainers.image.vendor="estahn" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.name="k8s-image-swapper" \
      org.label-schema.description="Mirror images into your own registry and swap image references automatically." \
      org.label-schema.url="https://github.com/estahn/k8s-image-swapper" \
      org.label-schema.vcs-url="git@github.com:estahn/k8s-image-swapper.git" \
      org.label-schema.vendor="estahn" \
      org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.label-schema.vcs-ref="$VCS_REF" \
      org.label-schema.build-date="$BUILD_DATE"
