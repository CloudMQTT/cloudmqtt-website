[CloudMQTT](http://addons.heroku.com/cloudmqtt) is an [add-on](http://addons.heroku.com) for providing a MQTT broker to your application(s). 

[MQTT](http://mqtt.org/) is a lightweight pub/sub protocol, especially suited for low processor/bandwidth units like sensors and built-in system, but also suited for fast communication within applications. 

CloudMQTT is exposed through the MQTT protocol for which there are supported client in Java, C, Python, Node.js, Ruby, Objective-C etc.

## Provisioning the add-on

CloudMQTT can be attached to a Heroku application via the CLI:

<div class="callout" markdown="1">
A list of all plans available can be found [here](http://addons.heroku.com/cloudmqtt).
</div>

    :::term
    $ heroku addons:add cloudmqtt
    -----> Adding cloudmqtt to sharp-mountain-4005... done, v18 (free)

Once CloudMQTT has been added a `CLOUDMQTT_URL` setting will be available in the app configuration and will contain the canonical URL used to access the newly provisioned CloudMQTT service instance. This can be confirmed using the `heroku config:get` command.

    :::term
    $ heroku config:get CLOUDMQTT_URL
    mqtt://user:pass@broker.cloudmqtt.com

After installing CloudMQTT the application should be configured to fully integrate with the add-on.

## Local setup

### Environment setup

After provisioning the add-on it’s necessary to locally replicate the config vars so your development environment can operate against the service.

<div class="callout" markdown="1">
Though less portable it’s also possible to set local environment variables using `export CLOUDMQTT_URL=value`.
</div>

Use [Foreman](config-vars#local-setup) to configure, run and manage process types specified in your app’s [Procfile](procfile). Foreman reads configuration variables from an .env file. Use the following command to add the CLOUDMQTT_URL values retrieved from heroku config to `.env`.

    :::term
    $ heroku config -s | grep CLOUDMQTT_URL >> .env
    $ more .env

<p class="warning" markdown="1">
Credentials and other sensitive configuration values should not be committed to source-control. In Git exclude the .env file with: `echo .env >> .gitignore`.
</p>

### Service setup

A MQTT server can be installed for use in a local development  environment.  Typically this entails installing a MQTT compatible server like Mosquitto and pointing the CLOUDMQTT_URL to this local service.

<table>
  <tr>
    <th>If you have...</th>
    <th>Install with...</th>
  </tr>
  <tr>
    <td>Mac OS X</td>
    <td style="text-align: left"><code>brew install mosquitto</code></td>
  </tr>
  <tr>
    <td>Ubuntu Linux</td>
    <td style="text-align: left"><pre><code>
curl http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key | \
 apt-key add -
curl http://repo.mosquitto.org/debian/mosquitto-repo.list > \
 /etc/apt/sources.list.d/mosquitto-repo.list
apt-get update
apt-get install mosquitto
</code></pre></td>
  </tr>
  <tr>
    <td>Windows</td>
    <td style="text-align: left"><a href="http://mosquitto.org/files/binary/win32/">Windows installer</a></td>
  </tr>
  <tr>
    <td>Other</td>
    <td style="text-align: left"><a href="http://mosquitto.org/download/">Mosquitto download page</a></td>
  </tr>
</table>

Your CLOUDMQTT_URL can then be subsituted with ```mqtt://localhost:1883```.

## Using with Ruby

Currently the most mature client library for Ruby is the synchronous [ruby-mqtt](https://github.com/njh/ruby-mqtt), the async [em-mqtt](https://github.com/njh/ruby-em-mqtt) as yet to support user/password before it's usable with CloudMQTT. 

First you need to add ```mqtt``` as a dependency to your ```Gemfile``` and execute  ```bundle install```. In the following code snippet you can see you how can publish and subscribe. Note that the client is synchronous so you have to use threads if you want to subscribe and do other things at the same time.

    :::ruby
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
          puts "#{topic}: #{message}"
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

Full sample code can be found here: [github.com/CloudMQTT/ruby-mqtt-example](https://github.com/CloudMQTT/ruby-mqtt-example)

Worth noting is that the client does not yet support other QoS levels than 0, ie. no publish acknowledge or redelivery.

## Using with Node.js

A good javascript MQTT library is [MQTT.js](https://github.com/adamvr/MQTT.js). Add ```mqtt``` to your ```package.json``` file. Then a simple example could look like this:

    :::javascript
    var mqtt = require('mqtt'), url = require('url');
    // Parse 
    var mqtt_url = url.parse(process.env.CLOUDMQTT_URL || 'mqtt://localhost:1883');
    var auth = (mqtt_url.auth || ':').split(':');

    // Create a client connection
    var client = mqtt.createClient(mqtt_url.port, mqtt_url.hostname, {
      username: auth[0],
      password: auth[1] 
    });

    client.on('connect', function() { // When connected

      // subscribe to a topic
      client.subscribe('hello/world', function() {
        // when a message arrives, do something with it
        client.on('message', function(topic, message, packet) {
          console.log("Received '" + message + "' on '" + topic + "'");
        });
      });

      // publish a message to a topic
      client.publish('hello/world', 'my message', function() {
        console.log("Message is published");
        client.end(); // Close the connection when published
      });
    });

A full sample web app which uses [MQTT.js](https://github.com/adamvr/MQTT.js), [Express.js](http://expressjs.com) and [SSE](http://html5doctor.com/server-sent-events/) to deliver messages from and to a web browser is available here: [github.com/CloudMQTT/mqtt-sse](https://github.com/CloudMQTT/mqtt-sse) and can be tested out here at [mqtt-sse.herokuapp.com](http://mqtt-sse.herokuapp.com/).

## Using with Python

The most feature complete MQTT client for Python is [Mosquitto](http://mosquitto.org/documentation/python/). Below you see an sample app which both publish and subscribes to CloudMQTT.

    :::python
    import mosquitto, os, urlparse

    # Define event callbacks
    def on_connect(mosq, obj, rc):
        print("rc: " + str(rc))

    def on_message(mosq, obj, msg):
        print(msg.topic + " " + str(msg.qos) + " " + str(msg.payload))

    def on_publish(mosq, obj, mid):
        print("mid: " + str(mid))

    def on_subscribe(mosq, obj, mid, granted_qos):
        print("Subscribed: " + str(mid) + " " + str(granted_qos))

    def on_log(mosq, obj, level, string):
        print(string)

    mqttc = mosquitto.Mosquitto()
    # Assign event callbacks
    mqttc.on_message = on_message
    mqttc.on_connect = on_connect
    mqttc.on_publish = on_publish
    mqttc.on_subscribe = on_subscribe

    # Uncomment to enable debug messages
    #mqttc.on_log = on_log

    # Parse CLOUDMQTT_URL (or fallback to localhost)
    url_str = os.environ.get('CLOUDMQTT_URL', 'mqtt://localhost:1883')
    url = urlparse.urlparse(url_str)

    # Connect
    mqttc.username_pw_set(url.username, url.password)
    mqttc.connect(url.hostname, url.port)

    # Start subscribe, with QoS level 0
    mqttc.subscribe("hello/world", 0)

    # Publish a message
    mqttc.publish("hello/world", "my message")

    # Continue the network loop, exit when an error occurs
    rc = 0
    while rc == 0:
        rc = mqttc.loop()
    print("rc: " + str(rc))

The full code can be seen at [github.com/CloudMQTT/python-mqtt-example](https://github.com/CloudMQTT/python-mqtt-example).

## Using with Java

The by far best MQTT client for Java/JVM is [Paho](http://eclipse.org/paho/). Please email [support@cloudmqtt.com](mailto:support@cloudmqtt.com) if you need help to get started. 

## Dashboard

The CloudMQTT dashboard allows you to monitor your current connection and message traffic statistics.

The dashboard can be accessed via the CLI:

    :::term
    $ heroku addons:open cloudmqtt
    Opening cloudmqtt for sharp-mountain-4005...

or by visiting the [Heroku apps web interface](http://heroku.com/myapps) and selecting the application in question. Select CloudMQTT from the Add-ons menu.

## Migrating between plans

All plan migrations are completely transparent and instantaneous. 

Use the `heroku addons:upgrade` command to migrate to a new plan.

    :::term
    $ heroku addons:upgrade cloudmqtt:newplan
    -----> Upgrading cloudmqtt:newplan to sharp-mountain-4005... done, v18 ($49/mo)
           Your plan has been updated to: cloudmqtt:newplan

## Removing the add-on

CloudMQTT can be removed via the  CLI.

<div class="warning" markdown="1">This will destroy all associated data and cannot be undone!</div>

    :::term
    $ heroku addons:remove cloudmqtt
    -----> Removing cloudmqtt from sharp-mountain-4005... done, v20 (free)

## Support

All CloudMQTT support and runtime issues should be submitted on of the [Heroku Support channels](support-channels). Any non-support related issues or product feedback is welcome at [support@cloudmqtt.com](mailto:support@cloudmqtt.com).


