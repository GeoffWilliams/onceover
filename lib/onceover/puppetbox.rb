require 'puppetbox'
require 'puppetbox/driver/vagrant'

class Onceover
  class PuppetBox

    # Provision a host and test it aginst a single role test, then remove it
    # @param host The name of the host as onceover knows it
    # @param puppet_class The puppet class (role) to run
    # @param config A hash of config information for vagrant - it will be saved
    #   as a JSON file and loaded inside the Vagrantfile
    # @param repo Onceover's representation of a control repository.  We mostly
    #   use it to obtain the checked-out control repo
    def provision_and_test(driver, host, puppet_class, config, repo)

      raise "Hosts must be a single host object, not an array" if host.is_a?(Array)
      raise "Class must be a single Class [String], not an array" unless puppet_class.is_a?(String)

      # for now just support the vagrant driver
      case driver
      when "vagrant"

        # For the moment, just use the checked out production environment inside
        # onceover's working directory.  The full path resolves to something like
        # .onceover/etc/puppetlabs/code/environments/production -- in the
        # directory your running onceover from
        #
        # we pass in our pre-configured logger instance for separation and to
        # reduce the amount of log output.  We only print puppet apply output for
        # failed runs, however, if user runs in onceover's --debug mode, then we
        # will print the customary ton of messages, including those from vagrant
        # itself.
        di = ::PuppetBox::Driver::Vagrant.new(
          host,
          "#{repo.tempdir}/etc/puppetlabs/code/environments/production",
          logger: logger
        )
      else
        raise "PuppetBox only supports driver: 'vagrant' at the moment (supplied: #{driver})"
      end
      result = ::PuppetBox.run_puppet(di, puppet_class)

      indent = "  "
      if result.passed
        logger.info("#{indent}#{host}:#{puppet_class} --> PASSED")
      else
        logger.error("#{indent}#{host}:#{puppet_class} --> FAILED")
        # since we stop running on failure, the error messages will be in the
        # last element of the result.messages array (tada!)
        messages = result.messages
        messages[-1].each { |line|
          # puts "XXXXXXX #{line}"
          logger.error "#{indent}#{host} - #{line}"
        }
        #   puts "size of result messages #{result.messages.size}"
        #   puts "size of result messages #{result.messages[0].size}"
        #   run.each { |message_arr|
        #     puts message_arr
        #     #message_arr.each { |line|
        #   #    puts line
        #   #  }
        #     # require 'pry'
        #     # binding.pry
        #     #puts "messages size"
        #     #puts messages.size
        #   #  messages.each { |message|
        #       # messages from the puppet run are avaiable in a nested array of run
        #       # and then lines so lets print each one out indended from the host so
        #       # we can see what's what
        #   #    logger.error("#{host}       #{message}")
        #   #  }
        #   }
        # }
      end
      result.passed
    end

  end
end
