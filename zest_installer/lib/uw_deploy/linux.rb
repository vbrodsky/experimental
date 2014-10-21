module UwDeploy
  class Linux
    class << self
      def deploy(name, version, suffix)
        if version.empty?
          system("sudo apt-get install -y #{name}")
        else
          system("sudo apt-get install -y #{name}=#{version}#{suffix}")
        end
      end

    end
  end
end
