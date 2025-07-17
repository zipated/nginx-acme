# Builder
FROM nginx:1.29.0-alpine

WORKDIR /root

# install req
RUN apk update && apk add bash curl openssl socat

# install acme.sh
RUN curl https://get.acme.sh | sh
RUN chmod +x /root/.acme.sh/acme.sh
RUN touch /root/.bashrc
RUN echo "export PATH=$PATH:/root/.acme.sh" >> .bashrc

# nkdir logs
RUN mkdir -p /etc/nginx/logs
RUN touch /etc/nginx/logs/access.log

# add entrypoint.sh
ADD ./docker/entrypoint.sh .
RUN chmod +x /root/entrypoint.sh
RUN chmod +x /root/auto_renew.sh

# expose
VOLUME ["/cert", "/etc/nginx/conf.d", "/etc/nginx/nginx.conf"]
CMD ["/bin/bash", "/root/entrypoint.sh"]
