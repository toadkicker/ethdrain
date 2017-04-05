#FROM kibana:5.3.0
FROM ubuntu:16.10
USER root

RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y systemd python-software-properties software-properties-common apt-transport-https
RUN add-apt-repository ppa:webupd8team/java -y && apt-get update
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
RUN apt-get install -y oracle-java8-installer oracle-java8-set-default
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
RUN echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-5.x.list
RUN apt-get update && apt-get install -y elasticsearch

RUN useradd -ms /bin/bash geth
WORKDIR /home/geth

RUN wget https://artifacts.elastic.co/downloads/kibana/kibana-5.3.0-amd64.deb
RUN dpkg -i kibana-5.3.0-amd64.deb

RUN add-apt-repository -y ppa:ethereum/ethereum && apt-get update && apt-get install -y ethereum

COPY etc/default/elasticsearch /etc/default/elasticsearch
COPY etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
COPY usr/lib/systemd/system/elasticsearch.service /usr/lib/systemd/system/elasticsearch.service
COPY usr/lib/systemd/system/geth.service /etc/systemd/system/geth.service
COPY usr/lib/systemd/system/ethdrain.service /etc/systemd/system/ethdrain.service
COPY ethdrain.py /home/geth/ethdrain.py
COPY requirements.txt /home/geth/requirements.txt

USER geth
RUN /usr/bin/geth account new
RUN /usr/bin/geth --rpc --fast &

RUN python3 ./ethdrain.py -s 0 -e 1000

# These commands seem to fail
#RUN systemctl daemon-reload
#RUN systemctl enable elasticsearch
#RUN systemctl start elasticsearch
#RUN systemctl enable geth
#RUN systemctl start geth
#RUN systemctl enable ethdrain
#RUN systemctl start ethdrain

ENTRYPOINT /bin/bash