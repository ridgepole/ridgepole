FROM centos:7

RUN yum install -y centos-release-scl && \
    yum-config-manager --enable rhel-server-rhscl-7-rpms && \
    yum install -y \
      rh-ruby25-dev \
      rh-ruby25-ruby-devel \
      make \
      gcc \
      gcc-c++ \
      git \
      rpm-build

RUN scl enable rh-ruby25 -- \
    gem install --no-document \
      bundler \
      omnibus

COPY Gemfile /
RUN scl enable rh-ruby25 -- \
    bundle install

WORKDIR /omnibus-ridgepole

ENTRYPOINT ["/usr/bin/scl", "enable", "rh-ruby25", "--"]
