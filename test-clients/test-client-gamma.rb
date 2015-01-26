require "multi_json"
require "net/ssh"
require 'uri'
require "renet"
require_relative "protocol-lib"

class TestClientGamma
  # include Celluloid

  def initialize(host, port)
    @client = ENet::Connection.new(host, port, 4, 0, 0)

    @client.on_connection(method(:on_connect))
    @client.on_packet_receive(method(:on_packet))
    @client.on_disconnection(method(:on_disconnect))

    @client.connect(2000)
    @client.send_packet("#{PROTOCOLS[:handshake_extend_hand]}", true, 0)
    run
  end

  def run
    loop do
      @client.update(0)
    end
    # line = @client.gets
    # p line
    # response = MultiJson.load(line)
    # public_key_pem = response['data']['public_key'] if response['mode'] == 'public_key'
    # public_key = OpenSSL::PKey::RSA.new public_key_pem
    # encrypted_auth_key_response = MultiJson.dump({'channel'=> 'handshake', 'mode' => 'authenticate', 'data' => {'auth_key' => "#{public_key.public_encrypt('HELLO_WORLD')}".force_encoding("utf-8")}})
    # p encrypted_auth_key_response
    # @client.puts("#{encrypted_auth_key_response.inspect}")
  end

  def on_packet(data = 0, channel = 0)
    p "P: #{data}-#{channel}"
    # @client.send_packet(data, true, channel)
  end

  def on_connect(data = 0, channel = 0)
    p "C: #{data}-#{channel}"
  end

  def on_disconnect(data = 0, channel = 0)
    p "D: #{data}-#{channel}"
  end
end

start_time = Time.now

TestClientGamma.new("localhost", 56789)

puts "Time to complete: #{Time.now-start_time}"
