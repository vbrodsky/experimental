module UwDeploy
  class DeployFromPackageConfigFileV2

    attr_reader :config, :logger

    include UwDeploy::S3FetchV2

    #def deploy
    #  @destination = new_resource.destination
    #  fetch_files @destination
    #end

    def initialize(config)
      @config = config
      @logger = config.logger
      @destination = config.dest
    end

    def deploy
      fetch_and_deploy_from config.package_file
    end

    # handle specific file types, including config files
    def fetch_and_deploy_from local_filename
      if local_filename.end_with?('.tsv')
        logger.info "Deploying contents of config file: #{local_filename}"
        process_config_file local_filename

      elsif local_filename.end_with?('.gz')
        Chef::Log.info "Deploying R package: #{local_filename}"
        execute "install custom R package #{local_filename}" do
          command "R CMD INSTALL #{local_filename}"
        end

      elsif local_filename.end_with?('.deb')
        Chef::Log.info "Deploying Debian package: #{local_filename}"
        package_base = Regexp.new(".*/([^/]+)_([^_/]+)\.deb$").match(local_filename)[1]
        dpkg_package "#{package_base}" do
          action :install
          source local_filename
        end
      end
    end

    # Processes config file, which must be TSV, and loads various package types
    # specified in the file, in the order specified, allowing dependencies.
    #
    # Config file format, per line, fields delimited by tab:
    #     <type> <name> [optional stuff]
    # where:
    #     <type> = [linux | R | dpkg]
    #
    # and where the fields that are available for each type are:
    #   type linux:
    #     linux <name> [<version>] [<suffix>]
    #     NOTE: version and suffix are not supported when loading linux packages into chef
    #
    #   type dpkg:
    #     dpkg <name> <site-base>
    #
    #   type R:
    #     R <name> [<version> <suffix> <site-base>]
    #
    # fields are defined as:
    #     <name> = package name, excluding version or suffix, e.g., klaR
    #     <version> = e.g., 2.5.12
    #     <suffix> = e.g., .tar.gz or -1lucid1_amd64.deb
    #     <site-base> =  e.g., http://lib.stat.cmu.edu/R/CRAN/bin/linux/ubuntu/lucid/3182457
    #                       or s3://bucket/dir/subdir
    def process_config_file filename
      f = ::File.open(filename, 'r')
      f.each_line("\n") do |line|
        # skip comments
        next if !((line =~ /^\s*#/).nil?)

        type, name, opt1, opt2, opt3 = line.gsub("\n", '').split("\t")
        case type
          when 'linux'
            version = opt1
            suffix = opt2
            logger.info "Installing Linux package: #{name}"
            # load the Linux package
            UwDeploy::Linux.deploy(name, version, suffix)
          when 'dpkg'
            d_sitebase = get_sitebase(opt1)
            object_name = d_sitebase + '/' + name
            logger.info "Deploying Debian package: #{name}"
            process_object object_name, @destination
          when 'R'
            r_sitebase = get_sitebase(opt3)
            object_name = r_sitebase + '/' + name + '_' + opt1 + opt2
            process_object object_name, @destination
          else
            f.close
            raise "Unrecognized package config type, aborting: #{type}"
        end
      end
      f.close
    end

  # handle specific file types, including config files
  def post_fetch local_filename
    if local_filename.end_with?('.tsv')
      logger.info "Deploying contents of config file: #{local_filename}"
      process_config_file local_filename

    elsif local_filename.end_with?('.gz')
      logger.info "Deploying R package: #{local_filename}"
      execute "install custom R package #{local_filename}" do
        command "R CMD INSTALL #{local_filename}"
      end

    elsif local_filename.end_with?('.deb')
      logger.info "Deploying Debian package: #{local_filename}"
      package_base = Regexp.new(".*/([^/]+)_([^_/]+)\.deb$").match(local_filename)[1]
      dpkg_package "#{package_base}" do
        action :install
        source local_filename
      end
    end
  end

    def get_sitebase base
      case base
        when /^s3:\/\/([^\/]+)\/(.*)$/
          # strip the protocol and bucket, to force use of the current bucket
          $2
        when /^http:/
          raise "Http sitebase paths not supported, aborting: #{base}"
        when /^file:/
          raise "File sitebase paths not supported, aborting: #{base}"
        else
          raise "Unrecognized sitebase path type, aborting: #{base}"
      end
    end
  end
end
