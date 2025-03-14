# frozen_string_literal: true

openhab_spec = Gem::Specification.new do |s|
  s.name = "openhab"
  s.version = -(ENV["OPENHAB_VERSION"] || "5.1.0")

  def s.deleted_gem?
    false
  end

  def s.installation_missing?
    false
  end
end

Gem::Specification.add_spec(openhab_spec)
Gem.post_reset { Gem::Specification.add_spec(openhab_spec) }
