module GameOverseer

  # GameOverseers' connection to the world
  #
  # This server uses the renet library, which is C bindings for the Enet networking library
  class ENetServer
    # @param host [String] host or ip for the server to run on
    # @param port [Integer] port for the server to run on
    # @param max_clients [Integer] max number of clients that can be connected at one time
    # @param channels [Integer] number of channels (See Enet documentation)
    # @param download_bandwidth [Integer] max bandwidth for downloading per-second (0 is unlimited)
    # @param upload_bandwidth [Integer] max bandwidth for uploading per-second (0 is unlimited)
    # @return [Thread]
    def initialize(host, port, packet_handler, encryption_handler, max_clients = 4, channels = 4, download_bandwidth = 0, upload_bandwidth = 0)
      GameOverseer::Console.log("Server> Started on: #{host}:#{port}.")
      GameOverseer::Services.enable
      GameOverseer::ENetServer.instance = self

      @message_manager = GameOverseer::MessageManager.instance
      @channel_manager = GameOverseer::ChannelManager.instance
      @client_manager = GameOverseer::ClientManager.instance
      @packet_handler = packet_handler.new
      @encryption_handler = encryption_handler.instance if encryption_handler

      @server = ENet::Server.new(port, max_clients, channels, download_bandwidth, upload_bandwidth) # Port, max clients, channels, download bandwidth, upload bandwith
      @server.use_compression(true)
      @terminate = false

      @server.on_connection(method(:on_connect))
      @server.on_packet_receive(method(:on_packet))
      @server.on_disconnection(method(:on_disconnect))

      run
    end

    # Runs the server in a Thread,, in a loop, calling update on the server.
    #
    # @return [Thread]
    def run
      Thread.new {
        loop do
          @server.update(1000)
          break if @terminate
        end
      }
    end

    # Called when a packet is received
    # @param client_id [Integer] ID of client
    # @param data [String] data client sent
    # @param channel [Integer] channel that this was sent to
    def on_packet(client_id, data, channel)
      handle_connection(client_id, data, channel)
    end

    # callled when a client connects
    # @param client_id [Integer] ID of client
    # @param ip_address [String] address of client
    def on_connect(client_id, ip_address)
      @client_manager.add(client_id, ip_address)
    end

    # callled when a client disconnects
    # @param client_id [Integer] ID of client
    def on_disconnect(client_id)
      @client_manager.remove(client_id)
    end

    # send message to a specific client
    # @param client_id [Integer] ID of client
    # @param message [String] message to be sent to client
    # @param reliable [Boolean] whether or not the packet is guaranteed to be received by the client
    # @param channel [Integer] what channel to send on
    def transmit(client_id, message, reliable = false, channel = ChannelManager::CHAT)
      @server.send_packet(client_id, message, reliable, channel)
    end

    # send message to all connected clients
    # @param message [String] message to be sent to clients
    # @param reliable [Boolean] whether or not the packet is guaranteed to be received by the clients
    # @param channel [Integer] what channel to send on
    def broadcast(message, reliable = false, channel = ChannelManager::CHAT)
      @server.broadcast_packet(message, reliable, channel)
    end

    # send data to the InputHandler for processing
    # @param data [Hash]
    # @param client_id [Integer] ID of client that sent the data
    def process_data(client_id, data)
      GameOverseer::InputHandler.process_data(client_id, data)
    end

    # Handles received packets from clients and sends them through the {PacketHandler} for pre-processing, then sends it on to {#process_data}
    # @param client_id [Integer]
    # @param data [String] data received from client
    # @param channel [Integer] channel that this packet was sent along
    def handle_connection(client_id, data, channel)
      _data = @packet_handler.receive(client_id, data)
      if _data
        process_data(client_id, _data)
      else
        # TODO: Better error handling :D
        transmit(client_id, '{"channel":"_error", "mode":"_error", "data":{"code":400, "message":"something went wrong, likely bad data!"}}', true, ChannelManager::FAULT)
      end
    end

    def terminate
      @terminate = true
    end

    def self.instance
      @instance
    end

    def self.instance=(_instance)
      @instance = _instance
    end
  end

  class ENetServerRunner
    attr_reader :supervisor
    def start(host, port, packet_handler = PacketHandler, encryption_handler = nil)
      @supervisor = GameOverseer::ENetServer.new(host, port, packet_handler, encryption_handler)
    end
  end
end
