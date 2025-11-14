import express from "express";
import { SensorRangkigRoutes } from "../modules/sensor_ranking/sensorRanking.route";

const router = express.Router();

const moduleRoutes = [
  // ... routes
  {
    path: "/ranking",
    route: SensorRangkigRoutes,
  },
];

moduleRoutes.forEach((route) => router.use(route.path, route.route));
export default router;
