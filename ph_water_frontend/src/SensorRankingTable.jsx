import { Link } from "react-router-dom";

const SensorRankingTable = ({ data }) => {
  return (
    <div className="mt-10 p-4 bg-[#0f172a] rounded-lg shadow-lg text-white">
      <h2 className="text-2xl font-semibold mb-4">
        Sensor Ranking{" "}
        <span className="text-lg">{`(Reload page after file upload)`}</span>{" "}
      </h2>

      <div className="overflow-x-auto">
        <table className="min-w-full text-sm text-left border-collapse">
          <thead className="bg-[#1e293b] text-gray-300 uppercase text-xs">
            <tr>
              <th className="px-4 py-3">#</th>
              <th className="px-4 py-3">Sensor ID</th>
              <th className="px-4 py-3">Total Score</th>
              <th className="px-4 py-3">Readings Count</th>
              <th className="px-4 py-3">Last Updated</th>
              <th className="px-4 py-3">Show Details</th>
            </tr>
          </thead>
          <tbody>
            {data?.map((sensor, index) => (
              <tr
                key={sensor.sensorId}
                className={`border-b border-gray-700 ${
                  sensor.totalScore > 0
                    ? "bg-green-900/30"
                    : sensor.totalScore < 0
                    ? "bg-red-900/30"
                    : "bg-gray-800/30"
                }`}
              >
                <td className="px-4 py-2">{index + 1}</td>
                <td className="px-4 py-2 font-medium">{sensor.sensorId}</td>
                <td className="px-4 py-2">{sensor.totalScore}</td>
                <td className="px-4 py-2">{sensor.readingCount}</td>
                <td className="px-4 py-2 text-sm text-gray-400">
                  {new Date(sensor.lastUpdated).toLocaleString()}
                </td>
                <td>
                  <Link
                    to={`/${sensor?.sensorId}`}
                    className="text-blue underline"
                  >
                    Details
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default SensorRankingTable;
