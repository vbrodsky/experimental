FROM ubuntu:14.04
MAINTAINER zestfinance vlb@zestfinance.com

#as root
#tiff4
RUN echo "deb http://cz.archive.ubuntu.com/ubuntu saucy main universe" >> /etc/apt/sources.list.d/extra.list

#this is for some other packages, do not remember which ones:
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty multiverse" >> /etc/apt/sources.list.d/extra.list

#since we have entered a saucy repository above for tiff4, we want to make sure trusty will be used, not saucy for all packages that exist in both repos 
RUN echo "APT::Default-Release \"trusty\";" >> /etc/apt/apt.conf

RUN apt-get update && RUN apt-get install -y wget


#AND s3cmd, if needed:
RUN wget -O- -q http://s3tools.org/repo/deb-all/stable/s3tools.key | sudo apt-key add -&&  wget -O/etc/apt/sources.list.d/s3tools.list http://s3tools.org/repo/deb-all/stable/s3tools.list &&  apt-get update && sudo apt-get install -y s3cmd
