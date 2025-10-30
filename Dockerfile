# =========================================================
# === Stage 1: Build FRONTEND =============================
# =========================================================
FROM --platform=$BUILDPLATFORM node:18.19.0 AS FRONT
WORKDIR /web

# Copy source FE
COPY ./web ./

# Bỏ cài đặt Cypress (cho nhanh build)
ENV CYPRESS_INSTALL_BINARY=0
ENV CI=1

# Cài deps và build FE
RUN yarn install --frozen-lockfile --network-timeout 1000000 \
 && NODE_OPTIONS="--max-old-space-size=4096" yarn run build


# =========================================================
# === Stage 2: Build BACKEND ==============================
# =========================================================
FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS BACK
WORKDIR /go/src/casdoor

# Copy toàn bộ mã nguồn backend (đã sửa controllers)
COPY . .

# Cài gói build cơ bản
RUN apk add --no-cache git build-base

# Build backend binary
RUN ./build.sh

# Lưu version info
RUN go test -v -run TestGetVersionInfo ./util/system_test.go ./util/system.go > version_info.txt


# =========================================================
# === Stage 3: Runtime Image ==============================
# =========================================================
FROM alpine:3.19 AS STANDARD
LABEL MAINTAINER="https://casdoor.org/"
ARG USER=casdoor
ARG TARGETOS
ARG TARGETARCH
ENV BUILDX_ARCH="${TARGETOS:-linux}_${TARGETARCH:-amd64}"

# Chuẩn bị môi trường
RUN sed -i 's/https/http/' /etc/apk/repositories && \
    apk add --update sudo tzdata curl ca-certificates && \
    update-ca-certificates && \
    adduser -D $USER -u 1000 && \
    echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER && \
    chmod 0440 /etc/sudoers.d/$USER && \
    mkdir logs && chown -R $USER:$USER logs

USER $USER
WORKDIR /app

# Copy binary backend và FE build
COPY --from=BACK --chown=$USER:$USER /go/src/casdoor/server_${BUILDX_ARCH} ./server
COPY --from=BACK --chown=$USER:$USER /go/src/casdoor/swagger ./swagger
COPY --from=BACK --chown=$USER:$USER /go/src/casdoor/conf/app.conf ./conf/app.conf
COPY --from=BACK --chown=$USER:$USER /go/src/casdoor/version_info.txt ./version_info.txt
COPY --from=FRONT --chown=$USER:$USER /web/build ./web/build

EXPOSE 8000
ENTRYPOINT ["/app/server"]


# =========================================================
# === Stage 4: Optional - All-in-one with MariaDB ==========
# =========================================================
FROM mariadb:10.11 AS ALLINONE
LABEL MAINTAINER="https://casdoor.org/"
ARG TARGETOS
ARG TARGETARCH
ENV BUILDX_ARCH="${TARGETOS:-linux}_${TARGETARCH:-amd64}"

RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates

WORKDIR /app
COPY --from=BACK /go/src/casdoor/server_${BUILDX_ARCH} ./server
COPY --from=BACK /go/src/casdoor/swagger ./swagger
COPY --from=BACK /go/src/casdoor/conf/app.conf ./conf/app.conf
COPY --from=BACK /go/src/casdoor/version_info.txt ./version_info.txt
COPY --from=FRONT /web/build ./web/build
COPY --from=BACK /go/src/casdoor/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash"]
CMD ["/docker-entrypoint.sh"]
