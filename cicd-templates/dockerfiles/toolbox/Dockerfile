FROM amazon/aws-cli
MAINTAINER Kelvin Guo

ADD kubectl /usr/bin/kubectl
RUN yum install -y git && \
    yum install -y jq  && \
    amazon-linux-extras install docker && \
    yum install -y python3 && \
    yum install python-pip -y && \
    chmod +x /usr/bin/kubectl


