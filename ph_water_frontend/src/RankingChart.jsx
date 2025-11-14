import {
  BarElement,
  CategoryScale,
  Chart as ChartJS,
  Legend,
  LinearScale,
  Tooltip,
} from "chart.js";
import { Bar } from "react-chartjs-2";

ChartJS.register(BarElement, CategoryScale, LinearScale, Tooltip, Legend);

const RankingChart = ({ data }) => {
  const backgroundColors = data?.map(() => {
    const r = Math.floor(Math.random() * 255);
    const g = Math.floor(Math.random() * 255);
    const b = Math.floor(Math.random() * 255);
    return `rgba(${r}, ${g}, ${b}, 0.7)`;
  });
  const API_LINK = import.meta.env.VITE_API_LINK;
  const chartData = {
    labels: data.map((sensor) => sensor.sensorId),
    datasets: [
      {
        label: "Average Score",
        data: data.map((sensor) => sensor.averageScore),
        backgroundColor: backgroundColors,
      },
    ],
  };

  const options = {
    responsive: true,
    plugins: {
      legend: {
        display: false,
      },
      tooltip: {
        callbacks: {
          label: function (context) {
            const sensor = data[context.dataIndex];
            return `Avg: ${sensor.averageScore}, Total: ${sensor.totalScore}, Count: ${sensor.readingCount}`;
          },
        },
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        title: { display: true, text: "Average Score" },
      },
      x: {
        ticks: {
          maxRotation: 90,
          minRotation: 45,
        },
      },
    },
  };

  return (
    <div className="p-4 bg-white shadow rounded-xl">
      <h2 className="text-xl font-semibold mb-4 text-center">Sensor Ranking</h2>
      <Bar data={chartData} options={options} />
    </div>
  );
};

export default RankingChart;
