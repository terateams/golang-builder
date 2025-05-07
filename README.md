# golang-builder

本项目提供一个用于 Go 开发的 Docker 镜像，其中包含 UPX 可执行文件压缩器。

## 特性

- 基于官方 `golang:latest` 镜像。
- 包含从源码构建的 UPX (Ultimate Packer for eXecutables)。
- 支持多平台构建 (默认为 amd64)。

## Dockerfile 概览

`Dockerfile` 采用多阶段构建：

1.  **`upx_builder` 阶段:**

    - 使用 `golang:latest` 作为基础镜像。
    - 下载并编译特定版本的 UPX (当前为 `${UPX_VERSION}`)。
    - 安装 UPX 构建所需的工具。
    - 将编译后的 `upx` 二进制文件复制到 `/usr/local/bin/upx`。

2.  **最终镜像阶段:**
    - 使用 `golang:latest` 作为基础镜像。
    - 从 `upx_builder` 阶段复制 `upx` 二进制文件。
    - 验证 UPX 安装。

## 如何使用

### 构建镜像

在项目目录中运行以下命令来构建 Docker 镜像：

```bash
docker build -t golang-builder .
```

构建时也可以指定 UPX 版本和目标平台：

```bash
docker build --build-arg UPX_VERSION=4.0.2 --build-arg TARGETPLATFORM=arm64 -t golang-builder .
```

### 运行镜像

可以将此镜像用作 Go 应用的基础镜像，或用于编译和压缩 Go 二进制文件。

例如：在容器内启动一个交互式 shell：

```bash
docker run -it --rm golang-builder bash
```

在容器内，你可以使用 Go 工具链和 UPX：

```bash
go version
upx --version
```

### 使用 UPX 压缩 Go 可执行文件

1.  构建你的 Go 应用：
    ```bash
    go build -o myapp main.go
    ```
2.  使用 UPX 压缩可执行文件：
    ```bash
    upx myapp
    ```

## Dockerfile 示例 (teamsdns)

以下是一个使用此 `golang-builder` 镜像来构建一个名为 `teamsdns` 的 Go 应用的 `Dockerfile` 示例：

```dockerfile
ARG VERSION

FROM --platform=${TARGETPLATFORM} teamsgpt.azurecr.io/gobuilder:latest AS builder

ARG CGO_ENABLED=0

COPY ./ /root/src/
WORKDIR /root/src/
RUN go build -ldflags "-s -w -extldflags '-static' -X main.version=${TARGETPLATFORM}/${VERSION}" -trimpath -o teamsdns
RUN upx --best --lzma teamsdns


FROM --platform=${TARGETPLATFORM} alpine:latest

RUN apk add --no-cache ca-certificates
RUN apk add --no-cache tzdata
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 设置缓冲区大小环境变量，默认为 4MB
ENV TEAMSDNS_BUFFER_SIZE_MB=4

COPY --from=builder /root/src/teamsdns /usr/bin/
```

## 贡献

欢迎贡献！请随时提交拉取请求或开启议题。
