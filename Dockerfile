# Use the official latest Ubuntu as a base image
FROM ubuntu:latest AS build

ENV HOME /app
WORKDIR /app

# Update the system and install necessary dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Rust and build the application
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . $HOME/.cargo/env \
    && git clone https://github.com/crypticmeta/ord.git /app/ord \
    && cd /app/ord \
    && git checkout ordapi \
    && cargo build --release

# Use a new stage to create the final image
FROM ubuntu:latest

WORKDIR /app

# Update the system and install necessary dependencies in the final image
RUN apt-get update && apt-get install -y \
    pv \
    nano \
    git \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Copy the ord program from the build stage
COPY --from=build /app/ord/target/release /app/ord/target/release

ARG GROUP_ID=1000
ARG USER_ID=1000
RUN groupadd -g ${GROUP_ID} ord \
    && useradd -u ${USER_ID} -g ord -d /app ord \
    && chown -R ord:ord /app

# Add a startup script and change permissions while still root
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Switch to the new non-root user
USER ord

# Expose port 8080
EXPOSE 8080

# Set the working directory to /app/ord
WORKDIR /app/ord

# Add the directory containing the ord executable to the PATH
ENV PATH="/app/ord/target/release:${PATH}"

# Start the application with rpc-url option
# Set the CMD instruction with additional flags
ENTRYPOINT ["/start.sh"]
