# frozen_string_literal: true

module OpenHABDev
  module_function

  def http_port
    ENV.fetch("OPENHAB_DEV_HTTP_PORT", "8081")
  end

  def ssh_port
    ENV.fetch("OPENHAB_DEV_SSH_PORT", "8102")
  end

  def client_args
    ["runtime/bin/client", "-a", ssh_port, "-p", "habopen"]
  end

  def environment(directory)
    {
      "CHECK_ROOT_INSTANCE_RUNNING" => "false",
      "LANG" => ENV["LANG"],
      "JAVA_HOME" => ENV["JAVA_HOME"],
      "KARAF_REDIRECT" => File.join(File.dirname(directory), "karaf.log"),
      "EXTRA_JAVA_OPTS" => "-Xmx4g",
      "OPENHAB_HOME" => directory,
      "OPENHAB_RUNTIME" => File.join(directory, "runtime"),
      "OPENHAB_CONF" => File.join(directory, "conf"),
      "OPENHAB_USERDATA" => File.join(directory, "userdata"),
      "OPENHAB_LOGDIR" => File.join(directory, "userdata/logs"),
      "OPENHAB_HTTP_PORT" => http_port,
      "OPENHAB_HTTPS_PORT" => ENV.fetch("OPENHAB_DEV_HTTPS_PORT", "8444"),
      "HOME" => directory,
      "PATH" => ENV["PATH"]
    }.compact
  end

  def command(directory, executable, *args)
    variables = environment(directory).map { |key, value| "#{key}=#{value}" }
    ["env", "-i", *variables, File.join(directory, executable), *args]
  end
end
