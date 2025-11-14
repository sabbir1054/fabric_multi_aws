import { useEffect, useState } from "react";
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

// ⛳️ Random 1K entries every time page reloads
const getRandomSpikeData = () => {
  return Array.from({ length: 1000 }, (_, i) => ({
    time: i + 1,
    nodeId: Math.floor(Math.random() * 101), // Fully random 0–100
  }));
};
const API_LINK = import.meta.env.VITE_API_LINK;
const NodeActivitySpikeGraph = () => {
  const [data, setData] = useState([]);

  // useEffect(() => {
  //   // ❗️Simulate random fetch
  //   setTimeout(() => {
  //     const randomData = getRandomSpikeData();
  //     console.log("Generated demo spike data:", randomData); // Inspect this
  //     setData(randomData);
  //   }, 500);
  // }, []);
  useEffect(() => {
    fetch(`${API_LINK}/api/v1/ranking/getNodeActivityOverTime`)
      .then((res) => res.json())
      .then((resData) => {
        if (resData?.data?.length > 0) {
          const formatted = resData.data.map((entry, index) => ({
            time: index + 1,
            nodeId: parseInt(entry.nodeId.replace("Sensor-", "")),
          }));
          setData(formatted);
        } else {
          console.warn("⚠️ No data from backend, using demo data.");
        }
      })
      .catch((err) => {
        console.error("❌ Fetch error. Using demo data:", err);
        setData(demoData);
      });
  }, []);
  return (
    <div className="p-6 bg-gray-900 rounded-xl shadow-lg ">
      <div className="text-center mb-4">
        <h2 className="text-2xl font-bold">Random Sensor Node Spikes</h2>
        <p className="text-sm text-gray-500">
          Fully random node activity at each time step
        </p>
      </div>

      <ResponsiveContainer width="100%" height={400}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis
            dataKey="time"
            interval={99}
            label={{ value: "Time Step", position: "insideBottom", dy: 10 }}
            tick={{ fontSize: 10 }}
          />
          <YAxis
            domain={[0, 100]}
            label={{ value: "Node", angle: -90, position: "insideLeft" }}
            tick={{ fontSize: 12 }}
          />
          <Tooltip formatter={(v) => `Sensor-${v}`} />
          <Line
            type="linear"
            dataKey="nodeId"
            stroke="#0e7673"
            strokeWidth={1.2}
            dot={false}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default NodeActivitySpikeGraph;
