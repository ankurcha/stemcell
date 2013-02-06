module Bosh::Agent::StemCell

  class NoOpBuilder < BaseBuilder

    attr_reader :build_vm_run, :package_stemcell_run, :setup_run

    def type
      "noop"
    end

    def initialize(opts={}, manifest={})
      @counter = 0
      super(opts, manifest)
    end

    def build_vm
      @logger.info "Build VM invoked"
      @counter += 1
      @build_vm_run = @counter
    end

    def package_stemcell
      @logger.info "VM packaged into a stemcell"
      @counter += 1
      @package_stemcell_run = @counter
    end

    def setup
      @logger.info "Setting up stemcell creation process."
      @counter += 1
      @setup_run = @counter
    end
  end

end
