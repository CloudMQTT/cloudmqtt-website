## Using with Node.js

A good javascript MQTT library is [MQTT.js](https://github.com/adamvr/MQTT.js). Add ```mqtt``` to your ```package.json``` file. Then a simple example could look like this:

```javascript
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
```

A full sample web app which uses [MQTT.js](https://github.com/adamvr/MQTT.js), [Express.js](http://expressjs.com) and [SSE](http://html5doctor.com/server-sent-events/) to deliver messages from and to a web browser is available here: [github.com/CloudMQTT/mqtt-sse](https://github.com/CloudMQTT/mqtt-sse) and can be tested out here at [mqtt-sse.herokuapp.com](http://mqtt-sse.herokuapp.com/).


