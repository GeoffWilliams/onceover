require 'puppetbox'
require 'puppetbox/driver/vagrant'

class Onceover
  class PuppetBox
    # commented methods don't seem needed?

    # def self.facts_to_vagrant_box(facts)
    #   warn "[DEPRECATION] #{__method__} is deprecated due to the removal of Beaker"
    #   # Gets the most similar vagrant box to the facts set provided, will accept a single fact
    #   # se or an array
    #
    #   if facts.is_a?(Array)
    #     returnval = []
    #     facts.each do |fact|
    #       returnval << self.facts_to_vagrant_box(fact)
    #     end
    #     return returnval
    #   end
    #
    #   begin
    #     if facts['os']['distro']['id'] == 'Ubuntu'
    #       os = 'ubuntu'
    #       version = facts['os']['distro']['release']['major']
    #     end
    #   rescue
    #     # Do nothing, this is the easiest way to handle the hash bing in different formats
    #   end
    #
    #   begin
    #     if facts['os']['distro']['id'] == 'Debian'
    #       os = 'Debian'
    #       version = facts['os']['distro']['release']['full']
    #     end
    #   rescue
    #     # Do nothing
    #   end
    #
    #   begin
    #     if facts['os']['family'] == "RedHat"
    #       os = 'centos'
    #       version = "#{facts['os']['release']['major']}.#{facts['os']['release']['minor']}"
    #     end
    #   rescue
    #     # Do nothing
    #   end
    #
    #   return "UNKNOWN" unless os.is_a?(String)
    #
    #   if facts['os']['architecture'] =~ /64/
    #     arch = '64'
    #   else
    #     arch = '32'
    #   end
    #
    #   "puppetlabs/#{os}-#{version}-#{arch}-puppet"
    # end
    #
    # # This will take a fact set and return the beaker platform of that machine
    # # This is necissary as beaker needs the platform set up correctly to know which
    # # commands to run when we do stuff. Personally I would prefer beaker to detect the
    # # platform as it would not be that hard, especially once puppet is installed, oh well.
    # def self.facts_to_platform(facts)
    #   warn "[DEPRECATION] #{__method__} is deprecated due to the removal of Beaker"
    #
    #   if facts.is_a?(Array)
    #     returnval = []
    #     facts.each do |fact|
    #       returnval << self.facts_to_platform(fact)
    #     end
    #     return returnval
    #   end
    #
    #   begin
    #     if facts['os']['family'] == 'RedHat'
    #       platform = 'el'
    #       version = facts['os']['release']['major']
    #     end
    #   rescue
    #     # Do nothing, this is the easiest way to handle the hash being in different formats
    #   end
    #
    #   begin
    #     if facts['os']['distro']['id'] == 'Ubuntu'
    #       platform = 'ubuntu'
    #       version = facts['os']['distro']['release']['major']
    #     end
    #   rescue
    #     # Do nothing, this is the easiest way to handle the hash being in different formats
    #   end
    #
    #   begin
    #     if facts['os']['distro']['id'] == 'Debian'
    #       platform = 'debian'
    #       version = facts['os']['distro']['release']['full']
    #     end
    #   rescue
    #     # Do nothing
    #   end
    #
    #   if facts['os']['architecture'] =~ /64/
    #     arch = '64'
    #   else
    #     arch = '32'
    #   end
    #
    #   "#{platform}-#{version}-#{arch}"
    # end
    #
    # # This little method will deploy a Controlrepo object to a host, just using r10k deploy
    # # control repo already deployed via shared folder :)
    # def self.deploy_controlrepo_on(host, repo = Onceover::Controlrepo.new())
    # end

    # This actually provisions a node and checks that puppet will be able to run and
    # be idempotent. It hacks the beaker NetworkManager object to do this. The reason
    # is that beaker is designed to run in the following order:
    #   1. Spin up nodes
    #   2. Run all tests
    #   3. Kill all nodes
    #
    # This is not helpful for us. We want to be able to test all of our classes on
    # all of our nodes, this could be a lot of vms and having them all running at once
    # would be a real kick in the dick for whatever system was running it.
    def provision_and_test(host, puppet_class, config, repo)

      raise "Hosts must be a single host object, not an array" if host.is_a?(Array)
      raise "Class must be a single Class [String], not an array" unless puppet_class.is_a?(String)

      # for now just support the vagrant driver
      di = ::PuppetBox::Driver::Vagrant.new(host, "#{repo.tempdir}/etc/puppetlabs/code/environments/production")
      res = ::PuppetBox.run_puppet(di, puppet_class)

    end

    # def self.match_indentation(test,logger)
    #   # warn "[DEPRECATION] #{__method__} is deprecated due to the removal of Beaker"
    #   #
    #   # logger.line_prefix = '  ' * (test.metadata[:scoped_id].split(':').count - 1)
    # end

    # def self.host_create(name, nodes)
    #   warn "[DEPRECATION] #{__method__} is deprecated due to the removal of Beaker"
    #
    #   require 'beaker/network_manager'
    #
    #   current_opts = {}
    #   nodes.each do |opt,val|
    #     if opt == :HOSTS
    #       val.each do |k,v|
    #         if k == name
    #           current_opts[:HOSTS] = {k => v}
    #         end
    #       end
    #     else
    #       current_opts[opt] = val
    #     end
    #   end
    #
    #   # I copied this code off the internet, basically it allows us
    #   # to refer to each key as either a string or an object
    #   current_opts.default_proc = proc do |h, k|
    #     case k
    #       when String then sym = k.to_sym; h[sym] if h.key?(sym)
    #       when Symbol then str = k.to_s; h[str] if h.key?(str)
    #     end
    #   end
    #
    #   @nwm = ::Beaker::NetworkManager.new(current_opts,logger)
    #   @nwm.provision
    #   @nwm.proxy_package_manager
    #   @nwm.validate
    #   @nwm.configure
    #
    #   @nwm.instance_variable_get(:@hosts).each do |host|
    #     host.instance_variable_set(:@nwm,@nwm)
    #     host.define_singleton_method(:down!) do
    #       @nwm.cleanup
    #     end
    #   end
    #
    #   raise "The networkmanager created too many machines! Only expecting one" if hosts.count > 1
    #   @nwm.instance_variable_get(:@hosts)[0]
    # end
  end
end
