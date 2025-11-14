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
const weightPoolData = [
  { time: 0, weight: 50000 },
  { time: 200, weight: 60000 },
  { time: 300, weight: 85000 },
  { time: 500, weight: 110000 },
  { time: 700, weight: 130000 },
  { time: 1000, weight: 150000 },
];
const API_LINK = import.meta.env.VITE_API_LINK;
const CentralWeightPoolGraph = () => {
  const [data, setData] = useState([]);

  useEffect(() => {
    fetch(`${API_LINK}/api/v1/ranking/getWeightPoolOverTime`)
      .then((res) => res.json())
      .then((resData) => {
        console.log(resData);

        if (resData?.data?.length > 0) {
          setData(resData.data);
        } else {
          console.warn("⚠️ No weight pool data found.");
        }
      })
      .catch((err) => {
        console.error("❌ Error fetching weight pool trend:", err);
      });
  }, []);
  console.log("fgdsf", data);

  return (
    <div className="w-full p-6 bg-gray-900 rounded-xl shadow-lg text-white space-y-10">
      <h2 className="text-center text-xl font-bold mb-2">
        Central Weight Pool Distribution Over Time
      </h2>

      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis
            dataKey="time"
            label={{ value: "Time", position: "insideBottom", dy: 10 }}
          />
          <YAxis
            label={{
              value: "Central Weight Pool",
              angle: -90,
              position: "insideLeft",
            }}
          />
          <Tooltip />
          <Line
            type="monotone"
            dataKey="weight"
            stroke="#0e7673"
            strokeWidth={2}
            dot={false}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default CentralWeightPoolGraph;
