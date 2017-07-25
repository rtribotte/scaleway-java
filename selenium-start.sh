#!/usr/bin/env bash

ROOT=/opt/selenium
CONF=$ROOT/config.json

cat <<_EOF
{
  "host": $(hostname -I | cut -d' ' -f1),
  "port": 4444,
  "role": "hub",
  "maxSession": 5,
  "newSessionWaitTimeout": 1,
  "capabilityMatcher": "org.openqa.grid.internal.utils.DefaultCapabilityMatcher",
  "throwOnCapabilityNotPresent": true,
  "jettyMaxThreads": -1,
  "cleanUpCycle": 5000,
  "browserTimeout": 0,
  "timeout": 30,
  "debug": false
}
_EOF /
> $CONF

echo "starting selenium hub with configuration:"
cat $CONF

if [ ! -z "$SE_OPTS" ]; then
  echo "appending selenium options: ${SE_OPTS}"
fi

function shutdown {
    echo "shutting down hub.."
    kill -s SIGTERM $NODE_PID
    wait $NODE_PID
    echo "shutdown complete"
}

/usr/bin/java -cp ${JAVA_OPTS} -jar /opt/selenium/selenium-server-standalone.jar -role hub -hubConfig $CONF ${SE_OPTS} &
NODE_PID=$!

#trap shutdown SIGTERM SIGINT
#wait $NODE_PID

# systemctl disable init-selenium

