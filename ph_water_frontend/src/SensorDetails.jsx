import axios from "axios";
import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
const API_LINK = import.meta.env.VITE_API_LINK;
const SensorDetails = () => {
  const params = useParams();
  const [data, setData] = useState([]);

  useEffect(() => {
    const fetchSensorGraphData = async () => {
      try {
        const response = await axios.get(
          `${API_LINK}/api/v1/ranking/sensorGraph/${params?.sensorId}`
        );

        setData(response?.data?.data);
      } catch (error) {
        console.error("Error fetching sensor graph data:", error);
      }
    };
    if (params?.sensorId) fetchSensorGraphData();
  }, [params?.sensorId]);

  const compositeMetric = (entry) => entry.pH + entry.doValue - entry.nh4 / 10;
  console.log(data);

  return (
    <div className="container mx-auto">
      <h1 className="text-center text-2xl my-5 mb-10 text-white">
        {params?.sensorId} Details
      </h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Moisture over time */}
        <div className="bg-white rounded-lg p-4 shadow">
          <h3 className="text-lg font-bold mb-2">Soil Moisture Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={data}>
              <Line type="monotone" dataKey="Moisture" stroke="#8884d8" />
              <CartesianGrid stroke="#ccc" />
              <XAxis
                dataKey="timestamp"
                tickFormatter={(t) => t.slice(11, 19)}
              />
              <YAxis />
              <Tooltip />
            </LineChart>
          </ResponsiveContainer>
        </div>
        {/* pH over time */}
        <div className="bg-white rounded-lg p-4 shadow">
          <h3 className="text-lg font-bold mb-2">pH Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={data}>
              <Line type="monotone" dataKey="pH" stroke="#82ca9d" />
              <CartesianGrid stroke="#ccc" />
              <XAxis
                dataKey="timestamp"
                tickFormatter={(t) => t.slice(11, 19)}
              />
              <YAxis />
              <Tooltip />
            </LineChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-white rounded-lg p-4 shadow">
          <h3 className="text-lg font-bold mb-2">Temperature Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={data}>
              <Line type="monotone" dataKey="temp" stroke="#82ca9d" />
              <CartesianGrid stroke="#ccc" />
              <XAxis
                dataKey="timestamp"
                tickFormatter={(t) => t.slice(11, 19)}
              />
              <YAxis />
              <Tooltip />
            </LineChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-white rounded-lg p-4 shadow">
          <h3 className="text-lg font-bold mb-2">CA Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={data}>
              <Line type="monotone" dataKey="ca" stroke="#82ca9d" />
              <CartesianGrid stroke="#ccc" />
              <XAxis
                dataKey="timestamp"
                tickFormatter={(t) => t.slice(11, 19)}
              />
              <YAxis />
              <Tooltip />
            </LineChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-white rounded-lg p-4 shadow">
          <h3 className="text-lg font-bold mb-2">Do Values Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={data}>
              <Line type="monotone" dataKey="doValue" stroke="#82ca9d" />
              <CartesianGrid stroke="#ccc" />
              <XAxis
                dataKey="timestamp"
                tickFormatter={(t) => t.slice(11, 19)}
              />
              <YAxis />
              <Tooltip />
            </LineChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-white rounded-lg p-4 shadow">
          <h3 className="text-lg font-bold mb-2">NH4 Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={data}>
              <Line type="monotone" dataKey="nh4" stroke="#82ca9d" />
              <CartesianGrid stroke="#ccc" />
              <XAxis
                dataKey="timestamp"
                tickFormatter={(t) => t.slice(11, 19)}
              />
              <YAxis />
              <Tooltip />
            </LineChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-white rounded-lg p-4 shadow">
          <h3 className="text-lg font-bold mb-2">Salinity Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={data}>
              <Line type="monotone" dataKey="salinity" stroke="#82ca9d" />
              <CartesianGrid stroke="#ccc" />
              <XAxis
                dataKey="timestamp"
                tickFormatter={(t) => t.slice(11, 19)}
              />
              <YAxis />
              <Tooltip />
            </LineChart>
          </ResponsiveContainer>
        </div>
        {/* Scatter plot Moisture */}
        {/* <div className="bg-white rounded-lg p-4 shadow">
          <h3 className="text-lg font-bold mb-2">Moisture Scatter Plot</h3>
          <ResponsiveContainer width="100%" height={300}>
            <ScatterChart>
              <CartesianGrid />
              <XAxis
                dataKey="timestamp"
                tickFormatter={(t) => t.slice(11, 19)}
                name="Time"
              />
              <YAxis dataKey="Moisture" name="Moisture" />
              <Tooltip cursor={{ strokeDasharray: "3 3" }} />
              <Legend />
              <Scatter name="Moisture" data={data} fill="#8884d8" />
            </ScatterChart>
          </ResponsiveContainer>
        </div> */}
        {/* Scatter plot pH */}
        {/* <div className="bg-white rounded-lg p-4 shadow">
          <h3 className="text-lg font-bold mb-2">pH Scatter Plot</h3>
          <ResponsiveContainer width="100%" height={300}>
            <ScatterChart>
              <CartesianGrid />
              <XAxis
                dataKey="timestamp"
                tickFormatter={(t) => t.slice(11, 19)}
                name="Time"
              />
              <YAxis dataKey="pH" name="pH" />
              <Tooltip cursor={{ strokeDasharray: "3 3" }} />
              <Legend />
              <Scatter name="pH" data={data} fill="#82ca9d" />
            </ScatterChart>
          </ResponsiveContainer>
        </div> */}
        {/* Composite score scatter plot */}
        {/* <div className="bg-white rounded-lg p-4 shadow col-span-1 md:col-span-2">
          <h3 className="text-lg font-bold mb-2">Composite Score Over Time</h3>
          <ResponsiveContainer width="100%" height={300}>
            <ScatterChart>
              <CartesianGrid />
              <XAxis
                dataKey="timestamp"
                tickFormatter={(t) => t.slice(11, 19)}
                name="Time"
              />
              <YAxis name="Composite Score" />
              <Tooltip cursor={{ strokeDasharray: "3 3" }} />
              <Legend />
              <Scatter
                name="Composite"
                data={data.map((entry) => ({
                  timestamp: entry.timestamp,
                  value: compositeMetric(entry),
                }))}
                fill="#ff7300"
                dataKey="value"
              />
            </ScatterChart>
          </ResponsiveContainer>
        </div> */}
      </div>
    </div>
  );
};

export default SensorDetails;
