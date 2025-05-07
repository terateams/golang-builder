FROM --platform=${TARGETPLATFORM:-amd64} golang:latest AS upx_builder

ARG UPX_VERSION=4.2.1

# 安装 UPX 源码构建所需工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget git make cmake g++ xz-utils build-essential ca-certificates python3 && \
    rm -rf /var/lib/apt/lists/*

# 编译 UPX
WORKDIR /upx

RUN git clone --depth 1 --branch v${UPX_VERSION} https://github.com/upx/upx.git . && \
    git submodule update --init --recursive && \
    make all && \
    cp build/release/upx /usr/local/bin/upx

# Golang builder image
FROM --platform=${TARGETPLATFORM:-amd64} golang:latest

# 从 upx_builder 阶段复制 UPX
COPY --from=upx_builder /usr/local/bin/upx /usr/local/bin/upx

# 验证 UPX 安装
RUN upx --version

