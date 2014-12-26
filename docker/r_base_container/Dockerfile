FROM vbrodsky:base_container
MAINTAINER zestfinance vlb@zestfinance.com

RUN mkdir -p /tmp/shared
ADD shared /tmp/shared
WORKDIR /tmp/shared
RUN ./install_pkg_config.sh config/r-config-3.1.1-dev.tsv sudo config/.s3cfg

