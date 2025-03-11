# frozen_string_literal: true

raise "#{__FILE__} is only meant to be required from the context of the Karaf console" unless $terminal

ENV["TERM"] = $terminal.type
