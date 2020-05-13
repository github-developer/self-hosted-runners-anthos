FROM ubuntu:18.04

# Update and download dependencies
RUN apt-get update
RUN apt-get install -y libssl-dev curl iputils-ping jq wget

# Download Docker for container builds on Kubernetes
ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 18.09.1
RUN wget -O docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" && \
    tar --extract --file docker.tgz --strip-components 1 --directory /usr/local/bin/ && \
    rm docker.tgz

# Directory for runner to operate in
RUN mkdir ./actions-runner
WORKDIR /home/actions-runner

# Download Actions runner
# https://github.com/terraform-google-modules/terraform-google-github-actions-runners/blob/598a38a72b7bbaf56be431c07de04752c521fd60/examples/gh-runner-gke-dind/Dockerfile#L28-L31
ARG GH_RUNNER_VERSION="2.262.1"
RUN curl -o actions.tar.gz --location "https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz" && \
    tar -zxf actions.tar.gz && \
    rm -f actions.tar.gz

# Install dependencies
RUN ./bin/installdependencies.sh

# Allow runner to run as root
ENV RUNNER_ALLOW_RUNASROOT=1

COPY startup.sh .

ENTRYPOINT ["./startup.sh"]
