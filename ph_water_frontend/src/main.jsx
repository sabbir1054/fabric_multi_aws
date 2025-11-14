import { createRoot } from "react-dom/client";
import { Route, BrowserRouter as Router, Routes } from "react-router-dom";
import App from "./App.jsx";
import { AvgValueAllSensor } from "./AvgValueAllSensor.jsx";
import "./index.css";
import SensorDetails from "./SensorDetails.jsx";
createRoot(document.getElementById("root")).render(
  <Router>
    <Routes>
      <Route path="/" element={<App />} />
      <Route path="/:sensorId" element={<SensorDetails />} />
      <Route path="/avgValue/:keyword" element={<AvgValueAllSensor />} />
    </Routes>
  </Router>
);
