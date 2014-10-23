module UwDeploy
  module S3FetchV2

    def initialize(config)
      @logger = config.logger
      @bucket_name = config.bucket
      
      s3 = AWS::S3.new()
      @bucket = s3.buckets[@bucket_name]
    end

    def fetch_files destination
      new_resource.objects.each do |object|
        Chef::Log.info "Looking for #{object}"
        process_object object, destination
      end
    end

  # @param object [String] file name in S3 bucket
  # @param destination [String] base download path
  #
    def process_object object, destination
    require 'debug'
      s3_document = @bucket.objects[object]
      raise "Object not found in #{@bucket_name}: #{object}" if !s3_document.exists?
      @logger.info "Found #{object} with tag #{s3_document.etag}"
      basename = Pathname.new(object).basename
      fetch_file s3_document, "#{destination}/#{basename}"
    end

    def fetch_file s3_document, local_filename
      if (files_differ?(s3_document, local_filename))
        do_fetch s3_document, local_filename
        post_fetch local_filename
      end
    end

    def files_differ? s3_document, local_filename
      if ::File.exists? local_filename
        local_filename_md5 = Digest::MD5.file(local_filename).hexdigest
        Chef::Log.info "Local file #{local_filename} has checksum #{local_filename_md5}"
        # Note: for very large files, etag is not just the MD5 hash, so this test will fail, but this
        # only results in duplicate file downloads when recheffing, so isn't worth the cost
        # of using a completely correct etag calculation.  See the second answer at:
        # http://stackoverflow.com/questions/6591047/etag-definition-changed-in-amazon-s3
        s3_document.etag.gsub('"', '') != local_filename_md5
      else
        Chef::Log.info "Local file #{local_filename} does not exist."
        true
      end
    end

    def do_fetch s3_document, local_filename
      @logger.info "Copying to #{local_filename}"
      ::File.open(local_filename, "w")  { |f|  f.write(s3_document.read) }
    end

    def post_fetch local_filename; end

  end
end
