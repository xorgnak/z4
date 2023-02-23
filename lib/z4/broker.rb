module Z4Broker
  @@CLIENT = PahoMqtt::Client.new
  PahoMqtt.logger = 'broker.log'
  @@CB = Hash.new { |h,k| h[k] = lambda() { |m| puts "#{m.topic}: #{m.payload}" } }
  def self.topic n, &b
    @@CB[n] = b
  end
  def self.callbacks
    @@CB
  end
  def self.publish t, p
    @@CLIENT.publish(t, p, false, 1)
  end
  def self.init!
    begin
    @@CLIENT.on_message do |message|
      @@CB.each_pair do |k,v|
        Z4Broker.callbacks[k].call(message)
      end
    end
    @@CLIENT.connect('localhost', 1883)
    @@CLIENT.subscribe(['#', 2])
    rescue => e
      puts "BrokerError"
    end
  end
end
