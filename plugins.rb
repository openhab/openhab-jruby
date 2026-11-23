# frozen_string_literal: true

Bundler::Plugin.add_hook(Bundler::Plugin::Events::GEM_BEFORE_EVAL) do |gemfile, _lockfile|
  # The repository shares a fixed lockfile across openHAB versions, including
  # when its specs run inside an addon-created ScriptEngine.
  version = "5.0.3" if File.exist?(File.join(File.dirname(gemfile), "openhab-scripting.gemspec"))

  # For user projects, the addon already supplies the actual openHAB gem.
  next if !version && defined?(org.openhab.core.OpenHAB.version)

  version ||= ENV["OPENHAB_VERSION"]&.tr("-", ".")

  # find a local openHAB installation
  if !version && (userdata = ENV["OPENHAB_USERDATA"]) &&
     File.exist?(version_file = File.join(userdata, "etc/version.properties"))
    version = File.read(version_file).strip[/^openhab-core\s*:\s*(\S+)$/, 1]&.tr("-", ".")
  end
  next unless version

  openhab_spec = Gem::Specification.new do |s|
    s.name = "openhab"
    s.version = version

    def s.deleted_gem?
      false
    end

    def s.installation_missing?
      false
    end
  end

  Gem::Specification.add_spec(openhab_spec)
  Gem.post_reset { Gem::Specification.add_spec(openhab_spec) }
end
