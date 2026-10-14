FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    FLUTTER_HOME=/opt/flutter \
    FLUTTER_VERSION=3.44.7 \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    PATH=/opt/flutter/bin:/opt/android-sdk/platform-tools:/usr/lib/jvm/java-17-openjdk-amd64/bin:${PATH}

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        git \
        libglu1-mesa \
        openjdk-17-jdk-headless \
        unzip \
        util-linux \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    archive="/tmp/flutter_linux_3.44.7-stable.tar.xz"; \
    curl --fail --location --retry 3 \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.7-stable.tar.xz" \
      --output "$archive"; \
    printf '%s  %s\n' 'a0edd646c159c0e816788c0e46a4f071199c1320495898f5a679599b583a05a4' "$archive" | sha256sum --check --strict -; \
    tar --extract --xz --no-same-owner --file "$archive" --directory /opt; \
    rm "$archive"; \
    CI=true flutter --version; \
    flutter config --no-analytics; \
    java --version

RUN mkdir -p /workspace "$ANDROID_HOME"

COPY docker/build-apk.sh /usr/local/bin/chami-build-apk
RUN chmod 0755 /usr/local/bin/chami-build-apk

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/chami-build-apk"]
