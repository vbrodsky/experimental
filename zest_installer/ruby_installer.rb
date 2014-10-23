$: << File.expand_path(File.dirname(__FILE__) + '/lib')

require 'optparse'
require 'ostruct'
require 'pp'
require 'csv'

require 'uw_deploy'
 

class InstallOperation
  Operation = 0
  Package_Name = 1

  class << self
    def install_success(status)
      succ = status==0 ? true : false
    end
  end
end

def verify(options)
  installation_steps = []

  CSV.foreach(options.package_file) do |r|
    line = r[0].strip
    next if line[0] =='#' #comment
    installation_steps.push line.split(/\s+/)
  end

  packages_not_installed = []
  installation_steps.each do |step|
    package_name = step[InstallOperation::Package_Name]
    installed = system("dpkg -l #{package_name}")
    packages_not_installed << package_name if !installed
  end

  if !packages_not_installed.empty?
    puts 'Packages not installed:'
    pp packages_not_installed
  else
    puts "***** All is fine! *****"
  end
end

options = OpenStruct.new
options.run = 'install'
options.log_file = 'log/installer.log'
options.dest= '/tmp'

OptionParser.new do |opts|
  opts.banner = "Usage: ruby ruby-installer.rb -p <package_file> -r <verify|install> -b<bucket(for install)> 
                 -l<log file> --dest-dir"
  
  opts.on("-r", "--run-command",
              "Command to run: currently only validate is supported") do |command|
    options.run = command
  end
  
  opts.on("-p", "--package-file [String]",
              "File listing packages to install") do |file|
    options.package_file = file
  end

  opts.on("-b", "--bucket-file",
              "S3 bucket name") do |file|
    options.bucket = file
  end

  opts.on("-l", "--log-file",
              "log file") do |log_file|
    options.log_file = log_file
  end
  
  opts.on('-d', "--dest",
              "destination path for downloaded files") do |dest|
    options.dest = dest
  end
end.parse!


options.logger = ::Logger.new(options.log_file)
case options.run
when 'install'
  UwDeploy::DeployFromPackageConfigFileV2.new(options).deploy
when 'verify'
  verify(options)
else
  UwDeploy::DeployFromPackageConfigFileV2.new(options).deploy
end
