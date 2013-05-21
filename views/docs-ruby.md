Currently the most mature client library for Ruby is the synchronous [ruby-mqtt](https://github.com/njh/ruby-mqtt), the async [em-mqtt](https://github.com/njh/ruby-em-mqtt) as yet to support user/password before it's usable with CloudMQTT. 

First you need to add ```mqtt``` as a dependency to your ```Gemfile``` and execute  ```bundle install```. In the following code snippet you can see you how can publish and subscribe. Note that the client is synchronous so you have to use threads if you want to subscribe and do other things at the same time.

```ruby
require 'mqtt'
require 'uri'

# Create a hash with the connection parameters from the URL
uri = URI.parse ENV['CLOUDMQTT_URL'] || 'mqtt://localhost:1883'
conn_opts = {
  remote_host: uri.host,
  remote_port: uri.port,
  username: uri.user,
  password: uri.password,
}

Thread.new do
  MQTT::Client.connect(conn_opts) do |c|
    # The block will be called when you messages arrive to the topic
    c.get('test') do |topic, message|
      puts "\#{topic}: \#{message}"
    end
  end
end

MQTT::Client.connect(conn_opts) do |c|
  # publish a message to the topic 'test'
  loop do
    c.publish('test', 'Hello World')
    sleep 1
  end
end
```

Full sample code can be found here: [github.com/CloudMQTT/ruby-mqtt-example](https://github.com/CloudMQTT/ruby-mqtt-example)

Worth noting is that the client does not yet support other QoS levels than 0, ie. no publish acknowledge or redelivery.

