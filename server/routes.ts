import type { Express } from "express";
import type { Server } from "http";
import { storage } from "./storage";
import { z } from "zod";
import crypto from "crypto";

function generateRefId(): string {
  return "TRP" + Math.random().toString(36).substr(2, 7).toUpperCase();
}

async function seedInitialTrips() {
  const trips = await storage.getTrips();
  if (trips.total === 0) {
    const customers = await storage.getUsers('customer');
    const drivers = await storage.getUsers('driver');
    const cats = await storage.getVehicleCategories();
    const zones = await storage.getZones();

    if (customers.data.length && cats.length && zones.length) {
      const statuses = ['completed', 'completed', 'completed', 'cancelled', 'ongoing', 'pending', 'completed'];
      const types = ['ride', 'ride', 'parcel', 'ride', 'ride', 'parcel', 'ride'];
      const pickups = [
        'Banjara Hills, Hyderabad', 'Jubilee Hills, Hyderabad', 'Secunderabad Station',
        'HITEC City, Hyderabad', 'Gachibowli, Hyderabad', 'Ameerpet, Hyderabad', 'LB Nagar, Hyderabad'
      ];
      const destinations = [
        'HITEC City, Hyderabad', 'Miyapur, Hyderabad', 'Gachibowli, Hyderabad',
        'Charminar, Hyderabad', 'Banjara Hills, Hyderabad', 'Uppal, Hyderabad', 'Kukatpally, Hyderabad'
      ];

      for (let i = 0; i < 7; i++) {
        const customer = customers.data[i % customers.data.length];
        const driver = drivers.data[i % drivers.data.length];
        const cat = cats[i % cats.length];
        const zone = zones[i % zones.length];
        const fare = (Math.random() * 200 + 50).toFixed(3);

        await storage.getTrips(); // just to avoid TS error, replace with actual insert via db
        const { db } = await import("./db");
        const { tripRequests } = await import("@shared/schema");
        await db.insert(tripRequests).values({
          refId: generateRefId(),
          customerId: customer.id,
          driverId: statuses[i] !== 'pending' ? driver?.id : undefined,
          vehicleCategoryId: cat.id,
          zoneId: zone.id,
          pickupAddress: pickups[i],
          destinationAddress: destinations[i],
          pickupLat: 17.4 + Math.random() * 0.2,
          pickupLng: 78.4 + Math.random() * 0.2,
          destinationLat: 17.4 + Math.random() * 0.2,
          destinationLng: 78.4 + Math.random() * 0.2,
          estimatedFare: fare,
          actualFare: statuses[i] === 'completed' ? fare : '0',
          estimatedDistance: Math.random() * 15 + 2,
          paymentMethod: ['cash', 'wallet', 'card'][i % 3],
          paymentStatus: statuses[i] === 'completed' ? 'paid' : 'unpaid',
          type: types[i],
          currentStatus: statuses[i],
        } as any).onConflictDoNothing();
      }
    }
  }
}

export async function registerRoutes(httpServer: Server, app: Express): Promise<Server> {
  // Seed trips after a short delay
  setTimeout(seedInitialTrips, 2000);

  // Dashboard
  app.get("/api/dashboard/stats", async (req, res) => {
    try {
      const stats = await storage.getDashboardStats();
      res.json(stats);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Auth
  app.post("/api/admin/login", async (req, res) => {
    try {
      const { email, password } = req.body;
      const admin = await storage.getAdminByEmail(email);
      if (!admin) return res.status(401).json({ message: "Invalid credentials" });
      res.json({ admin: { id: admin.id, name: admin.name, email: admin.email, role: admin.role } });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Users
  app.get("/api/users", async (req, res) => {
    try {
      const { userType, search, page, limit } = req.query;
      const result = await storage.getUsers(
        userType as string,
        search as string,
        Number(page) || 1,
        Number(limit) || 15
      );
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.get("/api/users/:id", async (req, res) => {
    try {
      const user = await storage.getUserById(req.params.id);
      if (!user) return res.status(404).json({ message: "User not found" });
      res.json(user);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.patch("/api/users/:id/status", async (req, res) => {
    try {
      const { isActive } = req.body;
      const user = await storage.updateUserStatus(req.params.id, isActive);
      res.json(user);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Trips
  app.get("/api/trips", async (req, res) => {
    try {
      const { status, search, page, limit } = req.query;
      const result = await storage.getTrips(
        status as string,
        search as string,
        Number(page) || 1,
        Number(limit) || 15
      );
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.get("/api/trips/:id", async (req, res) => {
    try {
      const trip = await storage.getTripById(req.params.id);
      if (!trip) return res.status(404).json({ message: "Trip not found" });
      res.json(trip);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.patch("/api/trips/:id/status", async (req, res) => {
    try {
      const { status } = req.body;
      const trip = await storage.updateTripStatus(req.params.id, status);
      res.json(trip);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Vehicle Categories
  app.get("/api/vehicle-categories", async (req, res) => {
    try {
      const cats = await storage.getVehicleCategories();
      res.json(cats);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/vehicle-categories", async (req, res) => {
    try {
      const cat = await storage.createVehicleCategory(req.body);
      res.status(201).json(cat);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.put("/api/vehicle-categories/:id", async (req, res) => {
    try {
      const cat = await storage.updateVehicleCategory(req.params.id, req.body);
      res.json(cat);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/vehicle-categories/:id", async (req, res) => {
    try {
      await storage.deleteVehicleCategory(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Zones
  app.get("/api/zones", async (req, res) => {
    try {
      const zoneList = await storage.getZones();
      res.json(zoneList);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/zones", async (req, res) => {
    try {
      const zone = await storage.createZone(req.body);
      res.status(201).json(zone);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.put("/api/zones/:id", async (req, res) => {
    try {
      const zone = await storage.updateZone(req.params.id, req.body);
      res.json(zone);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.patch("/api/zones/:id", async (req, res) => {
    try {
      const zone = await storage.updateZone(req.params.id, req.body);
      res.json(zone);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/zones/:id", async (req, res) => {
    try {
      await storage.deleteZone(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Trip Fares
  app.get("/api/fares", async (req, res) => {
    try {
      const fares = await storage.getTripFares();
      res.json(fares);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/fares", async (req, res) => {
    try {
      const fare = await storage.upsertTripFare(req.body);
      res.status(201).json(fare);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.put("/api/fares/:id", async (req, res) => {
    try {
      const fare = await storage.updateTripFare(req.params.id, req.body);
      res.json(fare);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/fares/:id", async (req, res) => {
    try {
      await storage.deleteTripFare(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Transactions
  app.get("/api/transactions", async (req, res) => {
    try {
      const { userId, page, limit } = req.query;
      const result = await storage.getTransactions(userId as string, Number(page) || 1, Number(limit) || 15);
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Coupons
  app.get("/api/coupons", async (req, res) => {
    try {
      const coupons = await storage.getCoupons();
      res.json(coupons);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/coupons", async (req, res) => {
    try {
      const coupon = await storage.createCoupon(req.body);
      res.status(201).json(coupon);
    } catch (e: any) {
      res.status(400).json({ message: e.message });
    }
  });

  app.put("/api/coupons/:id", async (req, res) => {
    try {
      const coupon = await storage.updateCoupon(req.params.id, req.body);
      res.json(coupon);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/coupons/:id", async (req, res) => {
    try {
      await storage.deleteCoupon(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Reviews
  app.get("/api/reviews", async (req, res) => {
    try {
      const { page, limit } = req.query;
      const result = await storage.getReviews(Number(page) || 1, Number(limit) || 15);
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Business Settings
  app.get("/api/settings", async (req, res) => {
    try {
      const settings = await storage.getBusinessSettings();
      res.json(settings);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/settings", async (req, res) => {
    try {
      const { keyName, value, settingsType } = req.body;
      const setting = await storage.upsertBusinessSetting(keyName, value, settingsType);
      res.json(setting);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Blogs
  app.get("/api/blogs", async (req, res) => {
    try {
      const blogList = await storage.getBlogs();
      res.json(blogList);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/blogs", async (req, res) => {
    try {
      const blog = await storage.createBlog(req.body);
      res.status(201).json(blog);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.put("/api/blogs/:id", async (req, res) => {
    try {
      const blog = await storage.updateBlog(req.params.id, req.body);
      res.json(blog);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/blogs/:id", async (req, res) => {
    try {
      await storage.deleteBlog(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Withdraw Requests
  app.get("/api/withdrawals", async (req, res) => {
    try {
      const { status } = req.query;
      const result = await storage.getWithdrawRequests(status as string);
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.patch("/api/withdrawals/:id/status", async (req, res) => {
    try {
      const { status } = req.body;
      const result = await storage.updateWithdrawStatus(req.params.id, status);
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Cancellation Reasons
  app.get("/api/cancellation-reasons", async (req, res) => {
    try {
      const reasons = await storage.getCancellationReasons();
      res.json(reasons);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/cancellation-reasons", async (req, res) => {
    try {
      const reason = await storage.createCancellationReason(req.body);
      res.status(201).json(reason);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/cancellation-reasons/:id", async (req, res) => {
    try {
      await storage.deleteCancellationReason(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  return httpServer;
}
