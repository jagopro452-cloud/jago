// ===========================================================================
// k6 Socket.IO Load Test — Concurrent WebSocket Connections
// ===========================================================================
// Usage: k6 run tests/enterprise/load/k6-socket-test.js

import { check } from 'k6';
import ws from 'k6/ws';
import { Rate, Trend, Counter } from 'k6/metrics';

const socketErrors = new Rate('socket_errors');
const connectionTime = new Trend('socket_connect_time', true);
const messageLatency = new Trend('socket_message_latency', true);
const totalConnections = new Counter('socket_connections');

const BASE_URL = __ENV.TEST_BASE_URL || 'http://localhost:5000';
const WS_URL = BASE_URL.replace('http://', 'ws://').replace('https://', 'wss://');

export const options = {
  scenarios: {
    // Gradual WebSocket connection ramp
    websocket_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 100 },
        { duration: '1m', target: 500 },
        { duration: '2m', target: 1000 },
        { duration: '2m', target: 2000 },
        { duration: '1m', target: 500 },
        { duration: '30s', target: 0 },
      ],
    },
  },
  thresholds: {
    socket_errors: ['rate<0.1'],           // <10% socket errors
    socket_connect_time: ['p(95)<3000'],   // Connect < 3s p95
  },
};

export default function () {
  const userId = `load-test-${__VU}-${__ITER}`;
  const socketUrl = `${WS_URL}/socket.io/?EIO=4&transport=websocket&userId=${userId}&token=loadtest&userType=driver`;

  const startTime = Date.now();

  const res = ws.connect(socketUrl, {}, function (socket) {
    totalConnections.add(1);
    connectionTime.add(Date.now() - startTime);

    socket.on('open', () => {
      // Send Socket.IO handshake
      socket.send('40');

      // Simulate driver location update every 3 seconds
      const intervalId = socket.setInterval(() => {
        const sendTime = Date.now();
        const locationPayload = JSON.stringify([
          'driver:location',
          {
            lat: 17.385 + (Math.random() * 0.1 - 0.05),
            lng: 78.486 + (Math.random() * 0.1 - 0.05),
            heading: Math.floor(Math.random() * 360),
            speed: Math.floor(Math.random() * 80),
          },
        ]);

        // Socket.IO event format: 42["event", data]
        socket.send(`42${locationPayload}`);
      }, 3000);

      // Keep connection open for 30s
      socket.setTimeout(() => {
        socket.close();
      }, 30000);
    });

    socket.on('message', (data) => {
      if (data.startsWith('42')) {
        messageLatency.add(Date.now() - startTime);
      }
    });

    socket.on('error', (e) => {
      socketErrors.add(1);
    });

    socket.on('close', () => {
      // Connection closed
    });
  });

  check(res, {
    'WebSocket connected': (r) => r && r.status === 101,
  }) || socketErrors.add(1);
}

export function handleSummary(data) {
  return {
    'tests/enterprise/reports/k6/socket-summary.json': JSON.stringify(data, null, 2),
  };
}
