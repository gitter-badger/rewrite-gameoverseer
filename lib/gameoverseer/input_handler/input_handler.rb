module GameOverseer
  class InputHandler
    def self.process_data(data, socket)
      @data = data
      @socket=socket
      if data_valid?
      end
    end

    def self.data_valid?
      if @data["channel"]
        if @data["mode"]
          forward_to_channel_manager
        end
      end
    end

    def self.forward_to_channel_manager
      count = 0
      begin
        channel_manager = ObjectSpace.each_object(GameOverseer::ChannelManager).first
        channel_manager.send_to_service(@data, @socket)
      rescue NoMethodError => e
        GameOverseer::Console.log("InputHandler> #{e.to_s}")
        raise if count >=5
        count+=1
        retry unless count >= 5
      end
    end
  end
end