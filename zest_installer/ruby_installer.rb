require 'optparse'
require 'ostruct'
require 'pp'
require 'csv'

$stdout = STDOUT

class InstallOperation
  Operation = 0
  Package_Name = 1

  class << self
    def install_success(status)
      succ = status==0 ? true : false
    end
  end
end


options = OpenStruct.new
options.run = 'validate'

OptionParser.new do |opts|
  opts.banner = "Usage: ruby ruby-installer.rb -c <config_file> -r <validate|install>"
  
  opts.on("-r", "--run command",
              "Command to run: currently only validate is supported") do |command|
    options.run = command
  end
  
  opts.on("-c", "--config file",
              "Install config gile") do |file|
    options.config = file
  end
end.parse!

installation_steps = []

CSV.foreach(options.config) do |r|
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
end
