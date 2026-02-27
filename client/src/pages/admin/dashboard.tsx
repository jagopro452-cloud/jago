import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Users, UserCheck, Car, CheckCircle, XCircle, MapPin, DollarSign, TrendingUp, Clock, Package } from "lucide-react";

function StatCard({ label, value, icon: Icon, color, sub }: any) {
  return (
    <Card className={`${color} border-0 shadow-sm`}>
      <CardContent className="p-5">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-1">{label}</p>
            <p className="text-3xl font-bold text-gray-800 dark:text-gray-100" data-testid={`stat-value-${label.toLowerCase().replace(/\s+/g, '-')}`}>
              {value?.toLocaleString() ?? <Skeleton className="h-8 w-20" />}
            </p>
            {sub && <p className="text-xs text-gray-500 dark:text-gray-500 mt-1">{sub}</p>}
          </div>
          <div className="w-12 h-12 rounded-xl bg-white/60 dark:bg-white/10 flex items-center justify-center">
            <Icon className="w-6 h-6 text-gray-700 dark:text-gray-300" />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

const statusColors: Record<string, string> = {
  completed: "bg-green-100 text-green-700",
  ongoing: "bg-blue-100 text-blue-700",
  pending: "bg-amber-100 text-amber-700",
  cancelled: "bg-red-100 text-red-700",
  accepted: "bg-purple-100 text-purple-700",
};

export default function Dashboard() {
  const { data: stats, isLoading } = useQuery<any>({
    queryKey: ["/api/dashboard/stats"],
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground" data-testid="page-title">Dashboard</h1>
          <p className="text-sm text-muted-foreground mt-0.5">Welcome back! Here's what's happening today.</p>
        </div>
        <div className="hidden sm:flex items-center gap-2 bg-card border rounded-lg px-3 py-2 text-sm text-muted-foreground">
          <Clock className="w-4 h-4" />
          {new Date().toLocaleDateString("en-IN", { weekday: "long", year: "numeric", month: "long", day: "numeric" })}
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        <StatCard label="Total Customers" value={stats?.totalCustomers} icon={Users} color="stat-card-blue" sub="Registered users" />
        <StatCard label="Total Drivers" value={stats?.totalDrivers} icon={UserCheck} color="stat-card-green" sub="Active partners" />
        <StatCard label="Total Trips" value={stats?.totalTrips} icon={Car} color="stat-card-amber" sub="All time" />
        <StatCard label="Completed Trips" value={stats?.completedTrips} icon={CheckCircle} color="stat-card-green" sub="Successfully done" />
        <StatCard label="Ongoing Trips" value={stats?.ongoingTrips} icon={TrendingUp} color="stat-card-cyan" sub="In progress" />
        <StatCard label="Cancelled Trips" value={stats?.cancelledTrips} icon={XCircle} color="stat-card-red" sub="All time" />
        <StatCard label="Active Zones" value={stats?.totalZones} icon={MapPin} color="stat-card-purple" sub="Service zones" />
        <StatCard label="Total Revenue" value={`₹${(stats?.totalRevenue || 0).toLocaleString("en-IN", { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`} icon={DollarSign} color="stat-card-amber" sub="From completed trips" />
      </div>

      {/* Recent Trips */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base font-semibold">Recent Trip Requests</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/30">
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Trip ID</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Customer</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden md:table-cell">Vehicle</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden sm:table-cell">Fare</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground">Status</th>
                  <th className="text-left px-4 py-3 font-medium text-muted-foreground hidden lg:table-cell">Date</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  Array(5).fill(0).map((_, i) => (
                    <tr key={i} className="border-b">
                      {Array(6).fill(0).map((_, j) => (
                        <td key={j} className="px-4 py-3"><Skeleton className="h-4 w-full" /></td>
                      ))}
                    </tr>
                  ))
                ) : stats?.recentTrips?.length ? (
                  stats.recentTrips.map((item: any) => (
                    <tr key={item.trip.id} className="border-b hover:bg-muted/20 transition-colors" data-testid={`trip-row-${item.trip.id}`}>
                      <td className="px-4 py-3 font-mono font-medium text-primary">{item.trip.refId}</td>
                      <td className="px-4 py-3 text-foreground">{item.customer?.fullName || "—"}</td>
                      <td className="px-4 py-3 text-muted-foreground hidden md:table-cell">{item.vehicleCategory?.name || "—"}</td>
                      <td className="px-4 py-3 hidden sm:table-cell">
                        ₹{Number(item.trip.actualFare || item.trip.estimatedFare).toFixed(0)}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${statusColors[item.trip.currentStatus] || "bg-gray-100 text-gray-700"}`}>
                          {item.trip.currentStatus}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs hidden lg:table-cell">
                        {new Date(item.trip.createdAt).toLocaleDateString("en-IN")}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="text-center py-12 text-muted-foreground">
                      No trips yet. Trips will appear here once customers start booking.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
