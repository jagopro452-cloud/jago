// ===========================================================================
// JagoPro — Socket.IO Test Client
// Reusable wrapper for connecting, authenticating, and asserting events
// ===========================================================================

import { io, Socket } from 'socket.io-client';
import config from '../config/test.config';
import { logger, sleep } from './helpers';

export interface SocketEvent {
  event: string;
  data: any;
  timestamp: number;
}

export class TestSocket {
  private socket: Socket | null = null;
  private receivedEvents: SocketEvent[] = [];
  private eventWaiters: Map<string, { resolve: (data: any) => void; reject: (err: Error) => void }[]> = new Map();

  constructor(
    private userId: string,
    private token: string,
    private userType: 'driver' | 'customer',
  ) {}

  async connect(timeout = config.timeouts.socket): Promise<this> {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(new Error(`Socket connection timeout (${timeout}ms)`));
      }, timeout);

      this.socket = io(config.baseUrl, {
        transports: ['websocket'],
        query: {
          userId: this.userId,
          token: this.token,
          userType: this.userType,
        },
        timeout,
        forceNew: true,
      });

      this.socket.on('connect', () => {
        clearTimeout(timer);
        logger.info(`Socket connected: ${this.userType}:${this.userId.slice(0, 8)}`);
        resolve(this);
      });

      this.socket.on('connect_error', (err) => {
        clearTimeout(timer);
        reject(new Error(`Socket connect error: ${err.message}`));
      });

      this.socket.on('auth:error', (data) => {
        clearTimeout(timer);
        reject(new Error(`Socket auth error: ${data.message}`));
      });

      // Capture all events
      this.socket.onAny((event, data) => {
        const entry: SocketEvent = { event, data, timestamp: Date.now() };
        this.receivedEvents.push(entry);
        logger.debug(`Socket[${this.userType}] received: ${event}`, JSON.stringify(data).slice(0, 200));

        // Resolve waiters
        const waiters = this.eventWaiters.get(event);
        if (waiters?.length) {
          const waiter = waiters.shift()!;
          waiter.resolve(data);
        }
      });
    });
  }

  emit(event: string, data: any): this {
    if (!this.socket?.connected) throw new Error('Socket not connected');
    this.socket.emit(event, data);
    logger.debug(`Socket[${this.userType}] emit: ${event}`, JSON.stringify(data).slice(0, 200));
    return this;
  }

  async waitForEvent(event: string, timeout = config.timeouts.socket): Promise<any> {
    // Check if already received
    const existing = this.receivedEvents.find(e => e.event === event);
    if (existing) {
      this.receivedEvents = this.receivedEvents.filter(e => e !== existing);
      return existing.data;
    }

    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        reject(new Error(`Timeout waiting for event: ${event} (${timeout}ms)`));
      }, timeout);

      if (!this.eventWaiters.has(event)) this.eventWaiters.set(event, []);
      this.eventWaiters.get(event)!.push({
        resolve: (data) => { clearTimeout(timer); resolve(data); },
        reject: (err) => { clearTimeout(timer); reject(err); },
      });
    });
  }

  hasReceived(event: string): boolean {
    return this.receivedEvents.some(e => e.event === event);
  }

  getEvents(event?: string): SocketEvent[] {
    return event
      ? this.receivedEvents.filter(e => e.event === event)
      : [...this.receivedEvents];
  }

  clearEvents() {
    this.receivedEvents = [];
  }

  get connected(): boolean {
    return this.socket?.connected ?? false;
  }

  get id(): string | undefined {
    return this.socket?.id;
  }

  disconnect() {
    if (this.socket) {
      this.socket.removeAllListeners();
      this.socket.disconnect();
      this.socket = null;
      logger.debug(`Socket[${this.userType}] disconnected`);
    }
  }
}

// ── Factory ─────────────────────────────────────────────────────────────────

export async function createDriverSocket(userId: string, token: string): Promise<TestSocket> {
  const sock = new TestSocket(userId, token, 'driver');
  await sock.connect();
  return sock;
}

export async function createCustomerSocket(userId: string, token: string): Promise<TestSocket> {
  const sock = new TestSocket(userId, token, 'customer');
  await sock.connect();
  return sock;
}
