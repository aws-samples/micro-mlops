FROM ubuntu:18.04
MAINTAINER Kelvin Guo

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Package dependencies
RUN apt-get update &&\
    apt-get install -y software-properties-common &&\
    add-apt-repository ppa:deadsnakes/ppa

RUN apt-get update
RUN apt-get install -y python3.6
RUN apt-get install -y python3-pip
RUN python3 -m pip install --upgrade pip
