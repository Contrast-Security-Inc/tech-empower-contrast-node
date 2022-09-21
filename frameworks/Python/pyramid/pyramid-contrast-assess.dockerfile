FROM python:3.10

ADD ./requirements.txt /pyramid/requirements.txt

# https://github.com/mopemope/meinheld/pull/123
RUN pip3 install --no-deps "meinheld==1.0.2"
RUN pip3 install -r /pyramid/requirements.txt
ADD ./ /pyramid
WORKDIR /pyramid

EXPOSE 8080

# Start Contrast Additions
COPY contrast-agent.tar.gz contrast-agent.tar.gz
COPY contrast_security.yaml /etc/contrast/contrast_security.yaml

ENV CONTRAST__ASSESS__ENABLE=true
ENV CONTRAST__PROTECT__ENABLE=false

RUN pip3 install ./contrast-agent.tar.gz
# End Contrast Additions

# Uses alternate gunicorn config
CMD gunicorn wsgi-contrast:app -c gunicorn_conf-contrast.py
