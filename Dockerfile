FROM alpine:latest

RUN apk add --no-cache bash jq xxd mediainfo ffmpeg parallel curl openjdk21-jre tzdata coreutils sed python3 py3-pip && ln -sf python3 /usr/bin/python
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache git python3 py3-pip && ln -sf python3 /usr/bin/python
RUN pip3 install --break-system-packages --no-cache --upgrade pip setuptools
RUN pip3 install --break-system-packages  git+https://github.com/mkb79/audible-cli

RUN git clone https://github.com/damajor/BALD /BALD

RUN /BALD/grab_additional_scripts.sh
RUN mkdir /root/.parallel
RUN touch /root/.parallel/will-cite

ENV TZ=Europe/Madrid
ENV INCONTAINER=true

CMD ["/BALD/BALD.sh"]