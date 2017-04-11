require "onceover/puppetbox"
class Onceover
  class Runner
    attr_reader :repo
    attr_reader :config

    def initialize(repo, config, mode = [:spec, :acceptance])
      @repo   = repo
      @config = config
      @mode   = [mode].flatten
      @command_prefix = ENV['BUNDLE_GEMFILE'] ? 'bundle exec ' : ''
    end

    def prepare!
      unless @config.skip_r10k
        # Deploy the puppetfile
        @config.r10k_deploy_local(@repo)
      end

      # Remove the entire spec directory to make sure we have
      # all the latest tests
      FileUtils.rm_rf("#{@repo.tempdir}/spec")

      # Create the other directories we need
      FileUtils.mkdir_p("#{@repo.tempdir}/spec/classes")
      FileUtils.mkdir_p("#{@repo.tempdir}/spec/acceptance/nodesets")

      # Copy our entire spec directory over
      FileUtils.cp_r("#{@repo.spec_dir}","#{@repo.tempdir}")

      # Create the Rakefile so that we can take advantage of the existing tasks
      @config.write_rakefile(@repo.tempdir, "spec/classes/**/*_spec.rb")

      # Create spec_helper.rb
      @config.write_spec_helper("#{@repo.tempdir}/spec",@repo)

      # Create spec_helper_accpetance.rb
      @config.write_spec_helper_acceptance("#{@repo.tempdir}/spec",@repo)

      # TODO: Remove all tests that do not match set tags

      if @mode.include?(:spec)
        # Verify all of the spec tests
        @config.spec_tests.each { |test| @config.verify_spec_test(@repo,test) }

        # Deduplicate and write the tests (Spec and Acceptance)
        @config.run_filters(Onceover::Test.deduplicate(@config.spec_tests)).each do |test|
          @config.write_spec_test("#{@repo.tempdir}/spec/classes",test)
        end
      end

      if @mode.include?(:acceptance)
        # Verify all of the acceptance tests
        @config.acceptance_tests.each { |test| @config.verify_acceptance_test(@repo,test) }

        # Write them out
        @config.write_acceptance_tests("#{@repo.tempdir}/spec/acceptance",@config.run_filters(Onceover::Test.deduplicate(@config.acceptance_tests)))
      end

      # Parse the current hiera config, modify, and write it to the temp dir
      unless @repo.hiera_config ==nil
        hiera_config = @repo.hiera_config
        hiera_config.each do |setting,value|
          if value.is_a?(Hash)
            if value.has_key?(:datadir)
              hiera_config[setting][:datadir] = "#{@repo.tempdir}/#{@repo.environmentpath}/production/#{value[:datadir]}"
            end
          end
        end
        File.write("#{@repo.tempdir}/#{@repo.environmentpath}/production/hiera.yaml",hiera_config.to_yaml)
      end

      @config.create_fixtures_symlinks(@repo)
    end

    def run_spec!
      Dir.chdir(@repo.tempdir) do
        #`bundle install --binstubs`
        #`bin/rake spec_standalone`
        if @config.opts[:parallel]
          logger.debug "Running #{@command_prefix}rake parallel_spec from #{@repo.tempdir}"
          exec("#{@command_prefix}rake parallel_spec")
        else
          logger.debug "Running #{@command_prefix}rake spec_standalone from #{@repo.tempdir}"
          exec("#{@command_prefix}rake spec_standalone")
        end
      end
    end

    def run_acceptance!
      logger.info "WOOOOOOOOOOO ACCEPTANCE TESTS"

      pb = Onceover::PuppetBox.new
      summary = {}
      @config.acceptance_tests.each { |test|
        # `test` contains the test matrix info from onceover.yaml, eg it contains
        # a packaged list of nodes and classes to run
        nodeset_yaml = @config.verify_acceptance_test(@repo,test)

        test.nodes.each { |node|
          summary[node.name] = {}
          if nodeset_yaml["HOSTS"][node.name].has_key?('config') and nodeset_yaml["HOSTS"][node.name].has_key?('driver')
            test.classes.each { |puppet_class|
              logger.info "Acceptance testing #{node.name} #{puppet_class.name}"
              summary[node.name][puppet_class.name] = pb.provision_and_test(
                nodeset_yaml["HOSTS"][node.name]["driver"],
                node.name,
                puppet_class.name,
                nodeset_yaml["HOSTS"][node.name]['config'],
                @repo,
              )
            }
          else
            message = "onceover-nodes.yaml missing `config` or `driver` element for #{node.name} (tests skipped)"
            summary[node.name] = message
          end
        }
      }

      # print the report summary
      indent = "  "
      puts "\n\n\nSummary\n======="
      summary.each { |node, class_results|
        puts node
        if class_results.class == String
          puts "#{indent}#{class_results}"
        else
          class_results.each { |puppet_class, passed|
            line = "#{indent}#{puppet_class}: #{passed ? "OK": "FAILED"}"
            if passed
              puts line.green
            else
              puts line.red
            end
          }
        end
      }

      # pb = Onceover::PuppetBox.new(repo)
      # pb.provision_and_test
      # def self.provision_and_test(host,puppet_class,opts = {},repo = Onceover::Controlrepo.new)
      #
      # Dir.chdir(@repo.tempdir) do
      #   #`bundle install --binstubs`
      #   #`bin/rake spec_standalone`
      #   logger.debug "Running #{@command_prefix}rake acceptance from #{@repo.tempdir}"
      #   exec("#{@command_prefix}rake acceptance")
      # end
    end
  end
end
