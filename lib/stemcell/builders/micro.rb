require 'stemcell/builders/ubuntu'

module Bosh::Agent::StemCell

  # This is concrete Stemcell builder for creating a Ubuntu micro-bosh stemcell
  # It creates a Ubuntu 11.04. The options passed are merged with
  # {
  #   :type => 'ubuntu',
  #   :iso => 'http://releases.ubuntu.com/11.04/ubuntu-11.04-server-amd64.iso',
  #   :iso_md5 => '355ca2417522cb4a77e0295bf45c5cd5',
  #   :iso_filename => 'ubuntu-11.04-server-amd64.iso'
  # }
  class MicroUbuntuBuilder < UbuntuBuilder

    # TODO: Do something that packages the things correctly

    def build_all_deps
      @logger.info "Build all bosh packages with dependencies"
      Dir.chdir(@bosh_src_root) do
        system("bundle exec rake all:build_with_deps")
      end
    end

    def release_tarball
      dir = File.join(@bosh_src_root, "release")
      tar = nil
      Dir.chdir(dir) do
        @logger.debug("Use #{dir}/config/microbosh_dev_template.yml as release manifest")
        FileUtils.cp File.join("config", "microbosh_dev_template.yml"), File.join("config", "dev.yml")
        @logger.info "Create bosh release"
        system("bosh create release --force --with-tarball") # Create release
        tar = Dir.glob("dev_releases/micro-bosh*.tgz").first()
      end
      tar ? File.expand_path(tar) : tar
    end

    def release_manifest
      manifest = File.join(@bosh_src_root, "release", "micro","#@infrastructure.yml")
    end

  end

end
