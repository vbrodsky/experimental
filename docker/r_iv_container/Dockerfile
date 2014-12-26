FROM vbrodsky:r_base_container
MAINTAINER zestfinance vlb@zestfinance.com

RUN mkdir -p /tmp/shared
ADD shared /tmp/shared
WORKDIR /tmp/shared
RUN apt-get update && ./install_pkg_config.sh config/iv-r-config-2.0.3-dev.tsv sudo config/.s3cfg

