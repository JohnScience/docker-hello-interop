# Source: https://github.com/rust-lang/docker-rust/blob/5008b6a718c798c342bb318f76f3531088bf426f/1.68.2/alpine3.17/Dockerfile

FROM alpine:3.17

RUN apk add --no-cache \
        ca-certificates \
        gcc \
        musl-dev

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.68.2

RUN set -eux; \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
        x86_64) rustArch='x86_64-unknown-linux-musl'; rustupSha256='241a99ff02accd2e8e0ef3a46aaa59f8d6934b1bb6e4fba158e1806ae028eb25' ;; \
        aarch64) rustArch='aarch64-unknown-linux-musl'; rustupSha256='6a2691ced61ef616ca196bab4b6ba7b0fc5a092923955106a0c8e0afa31dbce4' ;; \
        *) echo >&2 "unsupported architecture: $apkArch"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.25.2/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

RUN rustup default nightly && \
# strictly speaking, cbindgen is an overkill for this example but it's a convenient tool
# latest version: https://crates.io/crates/cbindgen
    cargo install --version 0.24.3 cbindgen

COPY hello_interop hello_interop
COPY from_rust from_rust
COPY from_c from_c
ADD cbindgen.toml cbindgen.toml

RUN cargo metadata \
        --all-features \
        --format-version 1 \
        --manifest-path hello_interop/Cargo.toml \
        > metadata.out && \
    cargo build --release --manifest-path hello_interop/Cargo.toml && \
    cargo build \
        --release \
        --features c_api \
        --target-dir hello_interop/c_api \
        --manifest-path hello_interop/Cargo.toml && \
    cargo build --release --manifest-path from_rust/Cargo.toml && \
    cd hello_interop && \
    cbindgen \
        --config ../cbindgen.toml \
        --output c_api/hello_interop.h \
        --metadata ../metadata.out && \
    cd ..
RUN gcc \
        -c \
        -Ihello_interop/c_api \
        from_c/main.c \
        -o from_c/hello_from_c.o && \
    gcc \
        -o \
        from_c/hello_from_c \
        from_c/hello_from_c.o \
        hello_interop/c_api/release/libhello_interop.a

ADD run.sh run.sh

ENTRYPOINT ["sh", "run.sh"]
# ENTRYPOINT [ "ls", "hello_interop/c_api/release" ]
# ENTRYPOINT [ "nm", "-g", "from_c/hello_from_c"]