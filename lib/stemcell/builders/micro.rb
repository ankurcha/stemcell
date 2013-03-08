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

    def type
      "micro"
    end

    def initialize(opts)
      #@bosh_src_root = opts[:bosh_src_root] || File.expand_path("bosh", @prefix)
      @release_manifest = opts[:release_manifest] # || default_release_manifest
      @release_tar = opts[:release_tar]
      if @release_manifest.nil? || @release_tar.nil?
        build_all_deps
        create_release_tarball
        exit 1
      end

      raise "Package compiler location required" if opts[:package_compiler].nil?
      # This is kind of a hack :(
      if opts[:package_compiler] && File.directory?(opts[:package_compiler])
        # Tar up the package
        tmpdir = Dir.mktmpdir
        tmp_package_compiler_tar = File.join(tmpdir, "_package_compiler.tar")
        Dir.chdir(opts[:package_compiler]) do
          sh "tar -cf #{tmp_package_compiler_tar} *"
          @package_compiler_tar = tmp_package_compiler_tar
        end
      else
        @package_compiler_tar = File.expand_path(opts[:package_compiler])
      end

      unless File.exists?(@release_manifest) && File.exists?(@release_tar) && File.exists?(@package_compiler_tar)
        raise "Please confirm #@release_tar, #@release_manifest and #@package_compiler_tar exists."
      end
      super(opts)
    end

    def setup
      # Do all the usual things
      super()
      FileUtils.cp @package_compiler_tar, File.join(definition_dest_dir, "_package_compiler.tar")
      FileUtils.cp @release_tar, File.join(definition_dest_dir, "_release.tgz")
      FileUtils.cp @release_manifest, File.join(definition_dest_dir, "_release.yml")
    end

    def build_all_deps
      @logger.info "Build all bosh packages with dependencies from source"
      @logger.info "Execute 'rake all:build_with_deps' in bosh/ directory"
    end

    def create_release_tarball
      @logger.info("Copy bosh/release/config/microbosh-dev-template.yml to bosh/release/config/dev.yml")
      @logger.info("Then execute 'bosh create release --force --with-tarball'")
      @logger.info("The release tar will be in bosh/release/dev_releases/micro-bosh*.tgz")
      @logger.info("The release manifest is at bosh/release/micro/vsphere.yml")
    end

    def pre_shutdown_hook
      ssh_download_file("/var/vcap/bosh/stemcell_dpkg_l.out", File.join(@prefix, "stemcell_dpkg_l.out"))
      ssh_download_file("/var/vcap/micro/apply_spec.yml", File.join(@prefix, "apply_spec.yml"))
    end

    def stemcell_files
      [File.join(@prefix, "stemcell_dpkg_l.out"), File.join(@prefix, "apply_spec.yml")]
    end

  end

end
