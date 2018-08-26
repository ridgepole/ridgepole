FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -y software-properties-common

RUN apt-add-repository -y ppa:brightbox/ruby-ng && \
    apt-get update && \
    apt-get install -y \
      ruby2.5 \
      ruby2.5-dev \
      build-essential \
      git

RUN gem install --no-document \
      bundler \
      omnibus

COPY Gemfile /
RUN bundle install

WORKDIR /omnibus-ridgepole
