FROM python:latest

WORKDIR /LDA

COPY . .

RUN apt update && \
    apt upgrade -y && \
    apt install -y git zip openssl && \
    pip install certbot certbot-dns-desec --break-system-packages 

# CMD [ "bash", "lets_enc.bash" ]
    
CMD ["/bin/bash"]

# docker build -t le .

# docker run -v .:/LDA -it --rm --name le le

# docker exec -it le /bin/bash