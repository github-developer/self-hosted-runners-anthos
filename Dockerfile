FROM ubuntu:latest

# Update and download dependencies
RUN apt-get update
RUN apt-get install -y libssl-dev curl iputils-ping jq wget

# Docker in docker for container builds on Kubernetes. Otherwise, follow this guidance: https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/.
ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 18.09.1
RUN wget -O docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" && \
    tar --extract --file docker.tgz --strip-components 1 --directory /usr/local/bin/ && \
    rm docker.tgz

# Directory for runner to operate in
RUN mkdir ./actions-runner
WORKDIR /home/actions-runner

COPY startup.sh .

EXPOSE 8080

ENTRYPOINT ["./startup.sh"]
