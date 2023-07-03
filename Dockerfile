# Use the official latest Ubuntu as a base image
FROM ubuntu:latest AS build

# Update the system and install necessary dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

WORKDIR /app

# Clone the ord repository
RUN git clone https://github.com/crypticmeta/ord.git ord

# List contents of /app/ord for debugging
RUN ls -la /app/ord

# Build the ord application
RUN . $HOME/.cargo/env \
    && cd ord \
    && git checkout ordapi \
    && cargo build --release

# List contents of /app/ord for debugging
RUN ls -la /app/ord

# Use a new stage to create the final image
FROM ubuntu:latest

# Update the system and install necessary dependencies in the final image
RUN apt-get update && apt-get install -y \
    pv \
    nano \
    git \
    curl \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y


# Copy the entire /app directory from the build stage
COPY --from=build /app /app

# Copy the start script and set permissions
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set user, group and working directory
ARG GROUP_ID=1000
ARG USER_ID=1000
RUN groupadd -g ${GROUP_ID} ord \
    && useradd -u ${USER_ID} -g ord -d /app ord \
    && chown -R ord:ord /app
USER ord
WORKDIR /app/ord

# Expose port 8080 and add the directory containing the ord executable to the PATH
EXPOSE 8080
ENV PATH="/app/ord/target/release:${PATH}"

# Set the CMD instruction with additional flags
ENTRYPOINT ["/start.sh"]

# To avoid file lock error

# go to /.cargo/registry/src/index.crates.io-6f17d22bba15001f/redb-0.13.0/src/tree_store/page_store/file_lock
# mut result and result = 0; 
