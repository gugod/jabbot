FROM perl:5.36
RUN cpanm -q App::cpm

WORKDIR /app
COPY . /app
RUN cpm install -g
