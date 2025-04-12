# frozen_string_literal: true

raise "#{__FILE__} is only meant to be required from the context of the Karaf console" unless $console

begin
  $terminal = $console.session.terminal
rescue NoMethodError
  puts "JRuby console is not available in this environment"
  exit
end

ENV["TERM"] = $terminal.type
