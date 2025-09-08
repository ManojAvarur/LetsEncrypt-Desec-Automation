FROM ubuntu:latest

WORKDIR /LDA

COPY . .

RUN apt update && \
    apt upgrade -y && \
    apt install -y dnsutils curl python3 pip git zip && \
    pip install certbot certbot-dns-desec --break-system-packages 

CMD [ "bash", "lets_enc.bash" ]