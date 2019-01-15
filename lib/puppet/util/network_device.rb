
require 'puppet'
require 'puppet/util/autoload'
require 'puppet/resource_api/transport/wrapper'


class Puppet::Util::NetworkDevice
  class << self
    attr_reader :current
  end

  def self.init(device)
    load_transports(device.provider)
    @current = Puppet::ResourceApi::Transport::Wrapper.new(device.provider, device.url) # will return a transport if one exists
  rescue Puppet::DevError, LoadError => detail
    if @current.nil?
      puts "Falling back to Device for: `#{device.provider}`"
      require "puppet/util/network_device/#{device.provider}/device"
      @current = Puppet::Util::NetworkDevice.const_get(device.provider.capitalize).const_get(:Device).new(device.url, device.options)
    end
  rescue => detail
    raise detail, _("Can't load %{provider} for %{device}: %{detail}") % { provider: device.provider, device: device.name, detail: detail }, detail.backtrace
  end

  def self.load_transports(transport_name)
    @schemas ||= Puppet::Util::Autoload.new(self, 'puppet/transport/schema')
    @schemas.load(transport_name, Puppet.lookup(:current_environment))
  end

  # Should only be used in tests
  def self.teardown
    @current = nil
  end
end
