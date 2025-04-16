# Use the official Ubuntu image as a base
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip zip wget xz-utils cmake clang ninja-build build-essential \
    openjdk-8-jdk pkg-config libgtk-3-dev libglib2.0-dev libgdk-pixbuf2.0-dev \
    libxcursor-dev libxrandr-dev libx11-dev libxi-dev libxss-dev libasound2-dev \
    nginx && \
    rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN wget -qO- https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.0-stable.tar.xz | tar -xJ -C /opt

# Set up environment variables
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$PATH:$FLUTTER_HOME/bin"

# Check Flutter installation and version
RUN flutter --version

# Set the working directory
WORKDIR /jewel
# Copy the app directory into the container
COPY ./jewel /jewel

# Copy the certificate and private key into the container
COPY ./certs/certificate.crt /etc/ssl/certs/certificate.crt
COPY ./certs/private.key /etc/ssl/private/private.key


RUN git config --global --add safe.directory /opt/flutter
# Run Flutter commands
RUN chmod +x ./jewelbuild.sh && ./jewelbuild.sh web

RUN flutter doctor

# Set up Nginx to serve the Flutter web app
RUN rm /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Expose necessary ports
EXPOSE 80 443

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]