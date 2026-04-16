FROM mcr.microsoft.com/devcontainers/universal:5

# Retry failed APT fetches up to 3 times to survive transient mirror sync issues
RUN echo 'APT::Acquire::Retries "3";' > /etc/apt/apt.conf.d/80retries
