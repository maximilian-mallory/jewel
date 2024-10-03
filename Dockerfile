# Use the official Ubuntu image as a base
FROM ubuntu:latest

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    zip \
    openjdk-8-jdk \
    wget \
    xz-utils \
    libglu1-mesa && \
    apt-get clean

# Install Flutter
RUN wget -qO- https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz | tar -xJ -C /opt

# Set up environment variables
ENV ANDROID_HOME=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$FLUTTER_HOME/bin"

# Create a non-root user
RUN useradd -m developer

# Switch to the non-root user
#USER developer

# Configure Git to trust the Flutter directory
RUN git config --global --add safe.directory /opt/flutter

# Check Flutter installation and version
RUN echo "Listing Flutter bin directory:" && ls /opt/flutter/bin && \
    echo "Flutter version:" && flutter --version

# Run flutter upgrade
RUN flutter upgrade

# Install Android SDK tools
RUN mkdir -p ${ANDROID_HOME} && \
    cd ${ANDROID_HOME} && \
    wget https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
    unzip sdk-tools-linux-4333796.zip && \
    rm sdk-tools-linux-4333796.zip

# Accept licenses and install SDK components
RUN yes | ${ANDROID_HOME}/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} --licenses && \
    ${ANDROID_HOME}/tools/bin/sdkmanager --sdk_root=${ANDROID_HOME} "build-tools;29.0.2" "platform-tools" "platforms;android-29"

# Set the working directory to the app directory
WORKDIR /jewel

# Copy the app directory into the container
COPY ./jewel /jewel

# Run Flutter commands
RUN flutter pub get
RUN flutter doctor
RUN flutter build web

# Command to run your app (optional)
CMD ["flutter", "run"]
