import { useEffect, useState } from "react";
import {
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Scatter,
  ScatterChart,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

export const AvgValueAllSensor = () => {
  const [dataSets, setDataSets] = useState({
    temp: [],
    pH: [],
    do: [],
    nh4: [],
    salinity: [],
    moisture: [],
    ca: [],
  });
  const API_LINK = import.meta.env.VITE_API_LINK;
  useEffect(() => {
    const metrics = ["temp", "pH", "do", "nh4", "salinity", "moisture", "ca"];
    metrics.forEach((metric) => {
      fetch(`${API_LINK}/api/v1/ranking/getSensorAveragesByKeyword/${metric}`)
        .then((res) => res.json())
        .then((data) => {
          setDataSets((prev) => ({ ...prev, [metric]: data?.data || [] }));
        });
    });
  }, []);

  const colors = {
    temp: "#8884d8",
    pH: "#ff7300",
    do: "#82ca9d",
    nh4: "#ffc658",
    salinity: "#a83279",
    moisture: "#4bc0c0",
    ca: "#f54291",
  };

  return (
    <div className=" p-6 bg-gray-900 rounded-xl shadow-lg text-white space-y-10">
      {Object.entries(dataSets).map(([key, data]) => (
        <div key={key}>
          <h2 className="text-2xl font-bold mb-4 text-center capitalize">
            Average {key} of All Sensors
          </h2>
          <ResponsiveContainer width="100%" height={400}>
            <ScatterChart>
              <CartesianGrid stroke="#444" strokeDasharray="3 3" />
              <XAxis
                dataKey="sensorId"
                name="Sensor ID"
                tick={{ fill: "#ccc", fontSize: 12 }}
              />
              <YAxis
                dataKey="average"
                name={key}
                tick={{ fill: "#ccc", fontSize: 12 }}
              />
              <Tooltip
                contentStyle={{ backgroundColor: "#333", borderRadius: 6 }}
                labelStyle={{ color: "#fff" }}
                itemStyle={{ color: "#ccc" }}
              />
              <Legend />
              <Scatter name={key} data={data} fill={colors[key]} />
            </ScatterChart>
          </ResponsiveContainer>
        </div>
      ))}
    </div>
  );
};
