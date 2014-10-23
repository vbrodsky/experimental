require 'uw_deploy/linux.rb'
require 'uw_deploy/s3_fetch_v2.rb'
require 'uw_deploy/deploy_from_pkg_config_file_v2.rb'


require 'logger'
require 'aws-sdk'
require 'digest/md5'

AWS.config(
:access_key_id => ENV['ACCESS_KEY'],
  :secret_access_key => ENV['SECRET_KEY'])

