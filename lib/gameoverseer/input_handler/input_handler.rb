module GameOverseer
  class InputHandler
    def self.process_data(data, client_id)
      @data = data
      @client_id = client_id
      data_valid?
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
        channel_manager = GameOverseer::ChannelManager.instance
        channel_manager.send_to_service(@data, @client_id)
      rescue NoMethodError => e
        GameOverseer::Console.log("InputHandler> #{e.to_s}")
        raise if count >=5
        count+=1
        retry unless count >= 5
      end
    end
  end
end
