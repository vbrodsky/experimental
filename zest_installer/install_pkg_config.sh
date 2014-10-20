#!/bin/bash -x
#
# Usage: $0 <config-file> [ sudo [<s3cmd-config-file> [<temp-dir>]]]
#
# Script that parses a config file containing specs for Linux and R packages,
# and installs those packages.
#
# Config file format, per line, fields delimited by tab:
#     <type> <name> [optional stuff]
# where:
#     <type> = [linux | R | dpkg]
#
# and where the fields that are available for each type are:
#   type linux (calls "apt-get install")):
#     linux <name> [<version>] [<suffix>]
#     NOTE: version and suffix are not supported when loading into chef
#
#   type dpkg (calls "dpkg -i"):
#     dpkg <name> <site-base>
#
#   type R (calls "R CMD INSTALL"):
#     R <name> [<version> <suffix> <site-base>]
#
# and fields are defined as:
#     <name> = package name, excluding version or suffix, e.g., klaR
#     <version> = e.g., 2.5.12
#     <suffix> = e.g., .tar.gz or -1lucid1_amd64.deb
#     <site-base> =  e.g., http://lib.stat.cmu.edu/R/CRAN/bin/linux/ubuntu/lucid/3182457
#                       or s3://bucket/dir/subdir

if [[ $# < 1 ]]
then
    echo "Usage: $0 <config-file> [ sudo [<s3cmd-config-file> [<temp-dir>]]]"
    exit -1
fi

INFILE=$1
SUDO=${2:-}
S3CFG=${3:-~/.s3cfg}
DEST_DIR=${4:-/tmp}

while IFS= read -r line
do
    line=$line
    echo $line | grep '^[[:space:]]*#' &> /dev/null
    if [[ $? == 0 ]]
    then
        echo "(skipping comment: $line)"
        continue
    fi

    type=`echo "$line" | cut -f 1`
    name=`echo "$line" | cut -f 2`

    if [[ "$type" == "linux" ]]
    then
        echo "@@@ installing linux pkg $name..."
        version=`echo "$line" | cut -f 3`
        suffix=`echo "$line" | cut -f 4`
        if [[ "$version" != "" ]]
        then
            sudo apt-get install -y "$name=$version$suffix"
        else
            sudo apt-get install -y $name
        fi

#    elif [[ "$type" == "test" ]]
#    then
#        echo installing test pkg $name...

    elif [[ "$type" == "dpkg" ]]
    then
        echo "@@@ installing debian pkg $name..."
        sitebase=`echo "$line" | cut -f 3`
        protocol=${sitebase%%:*}

        if [[ "$protocol" == "http" ]]
        then
            echo fetching debian pkg from $sitebase...
            if [[ ! -f $DEST_DIR/$name ]]
            then
                rm -f $DEST_DIR/$name
                wget -O$DEST_DIR/$name "$sitebase/$name"
            fi
            sudo dpkg -i $DEST_DIR/$name

        elif [[ "$protocol" == "s3" ]]
        then
            echo retrieving debian pkg from $sitebase...
            bucket=${sitebase#s3://}
            rm -f $DEST_DIR/$name
            s3cmd -c $S3CFG get --force "$sitebase/$name" $DEST_DIR/$name
            sudo dpkg -i $DEST_DIR/$name

        elif [[ "$protocol" == "file" ]]
        then
            filepath=${sitebase##*://}
            echo reading debian pkg from $filepath...
            sudo dpkg -i $filepath/$name

        else
            echo "ERROR: skipping debian pkg $name, unknown source: $sitebase"
        fi

    elif [[ "$type" == "R" ]]
    then
        echo "@@@ installing R pkg $name..."
        export R_LIBS_USER=~/.Rlibs

        version=`echo "$line" | cut -f 3`
        suffix=`echo "$line" | cut -f 4`
        sitebase=`echo "$line" | cut -f 5`
        pkgname="${name}_$version$suffix"
        protocol=${sitebase%%:*}

        if [[ "$protocol" == "http" ]]
        then
            echo fetching R pkg from $sitebase...
            if [[ ! -f $DEST_DIR/$pkgname ]]
            then
                rm -f $DEST_DIR/$name
                wget -O$DEST_DIR/$pkgname "$sitebase/$pkgname"
            fi
            $SUDO R CMD INSTALL $DEST_DIR/$pkgname

        elif [[ "$protocol" == "s3" ]]
        then
            echo retrieving R pkg from $sitebase...
            bucket=${sitebase#s3://}
            rm -f $DEST_DIR/$name
            s3cmd -c $S3CFG get --force "$sitebase/$pkgname" $DEST_DIR/$pkgname
            $SUDO R CMD INSTALL $DEST_DIR/$pkgname

        elif [[ "$protocol" == "file" ]]
        then
            filepath=${sitebase##*://}
            $SUDO R CMD INSTALL $filepath/$pkgname

        else
            $SUDO R --vanilla <<EOS
                options(repos='http://cran.us.r-project.org')
                install.packages('$name', dependencies=TRUE)
EOS
        fi

    else
        echo "Error: Unrecognized package type: $type"
        exit -1
    fi

done < "$INFILE"
