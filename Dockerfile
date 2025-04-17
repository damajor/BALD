FROM alpine:edge

RUN mkdir /BALD
COPY . /BALD

RUN apk -i update
RUN apk -i --no-cache upgrade
RUN apk add --no-cache bash jq xxd mediainfo ffmpeg parallel curl openjdk21-jre tzdata coreutils sed python3 py3-pip bc git && ln -sf python3 /usr/bin/python
RUN apk add atomicparsley --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
ENV PYTHONUNBUFFERED=1
RUN pip3 install --break-system-packages --no-cache --upgrade pip setuptools
RUN pip3 install --break-system-packages  git+https://github.com/mkb79/audible-cli

RUN /BALD/grab_additional_scripts.sh
RUN mkdir /root/.parallel
RUN touch /root/.parallel/will-cite

ENV TZ=Europe/Madrid
ENV INCONTAINER=true

CMD ["/BALD/BALD.sh"]