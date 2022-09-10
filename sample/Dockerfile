FROM public.ecr.aws/u9r5j5n7/ubuntu18.04-python37
MAINTAINER Kelvin Guo

COPY requirements.txt /src/requirements.txt
RUN cd /src && pip3 install -r /src/requirements.txt
RUN mkdir /src/logs

COPY . /src
WORKDIR /src

EXPOSE 5000

ENV FLASK_APP application.py
CMD ["flask", "run", "--host", "0.0.0.0"]
