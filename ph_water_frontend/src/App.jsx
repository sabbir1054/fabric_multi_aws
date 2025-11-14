import axios from "axios";
import { useEffect, useState } from "react";
import { useDropzone } from "react-dropzone";
import { toast, Toaster } from "sonner";
import { AvgValueAllSensor } from "./AvgValueAllSensor";
import CentralWeightPoolGraph from "./CentralWeightPoolGraph";
import NodeActivityGraph from "./NodeActivityGraph";
import RankingChart from "./RankingChart";
import SensorRankingTable from "./SensorRankingTable";
import SpinnerOverlay from "./SpinnerOverlay";
const API_LINK = import.meta.env.VITE_API_LINK;
function App() {
  const [tableData, setTableData] = useState([]);
  const [file, setFile] = useState(null);
  const [fileName, setFileName] = useState("");
  const [uploading, setUploading] = useState(false);
  const [message, setMessage] = useState("");
  const [weightPool, setWeghtPool] = useState(0);

  const onDrop = (acceptedFiles) => {
    const selectedFile = acceptedFiles[0];
    if (selectedFile && selectedFile.type === "text/csv") {
      setFile(selectedFile);
      setFileName(selectedFile.name);
      setMessage("");
    } else {
      setMessage("Only CSV files are allowed.");
    }
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { "text/csv": [".csv"] },
    multiple: false,
  });

  const getWeightPool = () => {
    fetch(`${API_LINK}/api/v1/ranking/weightPool`)
      .then((res) => res.json())
      .then((data) => setWeghtPool(data?.data?.value));
  };

  const getRanking = () => {
    fetch(`${API_LINK}/api/v1/ranking`)
      .then((res) => res.json())
      .then((data) => setTableData(data?.data));
  };

  const handleUpload = async () => {
    if (!file) {
      setMessage("Please select a CSV file before submitting.");
      return;
    }

    const formData = new FormData();
    formData.append("file", file);

    try {
      setUploading(true);
      setMessage("");

      const res = await axios.post(
        `${API_LINK}/api/v1/ranking/uploadCsv/batch`,
        formData,
        {
          headers: {
            "Content-Type": "multipart/form-data",
          },
        }
      );

      if (res?.data?.statusCode === 200) {
        toast.success("Upload done");
        getRanking();
        getWeightPool();
        setMessage("File uploaded successfully.");
        setFile(null);
      }
    } catch (err) {
      console.error(err);
      setMessage("Upload failed. Please try again.");
    } finally {
      setUploading(false);
    }
  };

  useEffect(() => {
    getRanking();
    getWeightPool();
  }, []);

  if (uploading) return <SpinnerOverlay />;

  return (
    <>
      <Toaster position="top" />
      <div className="min-h-screen bg-[#121212] text-white p-6">
        <h1 className="text-3xl font-semibold text-center mb-10">
          Sensor Ranking Dashboard
        </h1>
        {/* MIDDLE SECTION: Centered Upload + Weight Pool */}
        <div className="flex flex-col items-center justify-center mb-10">
          <div className="w-full lg:w-[600px] flex flex-col items-center gap-6">
            {/* Upload CSV */}
            <div className="p-6 w-full bg-[#1e1e2f] rounded-xl border border-gray-700 shadow-md">
              <h2 className="text-2xl font-semibold mb-4">Upload CSV File</h2>
              <div
                {...getRootProps()}
                className={`p-6 border-4 border-dashed rounded-lg text-center cursor-pointer transition duration-300 ${
                  isDragActive
                    ? "border-blue-400 bg-[#2a2a40]"
                    : "border-gray-600 bg-[#2a2a40] hover:border-blue-500"
                }`}
              >
                <input {...getInputProps()} />
                <p className="text-gray-300">
                  {fileName ||
                    "📁 Drag and drop CSV file here, or click to select"}
                </p>
              </div>
              {message && (
                <p className="mt-3 text-sm text-yellow-400">{message}</p>
              )}
              <button
                onClick={handleUpload}
                disabled={!file || uploading}
                className={`mt-5 w-full py-2 px-4 rounded-md font-medium transition ${
                  uploading || !file
                    ? "bg-gray-600 cursor-not-allowed text-gray-300"
                    : "bg-blue-600 hover:bg-blue-700 text-white"
                }`}
              >
                {uploading ? "Uploading..." : "Submit CSV"}
              </button>
            </div>

            {/* Weight Pool */}
            <div className="w-full bg-[#1e1e2f] p-6 rounded-xl border border-gray-700 text-center shadow-md">
              <h2 className="text-xl font-semibold mb-2">Weight Pool</h2>
              <p className="text-3xl font-bold text-blue-400">{weightPool}</p>
            </div>
          </div>
        </div>

        {tableData?.length > 0 && (
          <div className="container mx-auto  mb-10 bg-[#1e1e2f] p-6 rounded-xl border border-gray-700 shadow-md">
            <h2 className="text-2xl font-semibold mb-4 text-center">
              Ranking Graph
            </h2>
            <RankingChart data={tableData} />
          </div>
        )}
        {/* scatter plots */}
        {tableData?.length > 0 && <AvgValueAllSensor />}
        {tableData?.length > 0 && <NodeActivityGraph />}
        {tableData?.length > 0 && <CentralWeightPoolGraph />}
        {tableData?.length > 0 && (
          <div className="container mx-auto bg-[#1e1e2f] p-6 rounded-xl border border-gray-700 shadow-md">
            <h2 className="text-2xl font-semibold mb-4 text-center">
              Sensor Ranking Table
            </h2>
            {tableData?.length > 0 ? (
              <SensorRankingTable data={tableData} />
            ) : (
              <p className="text-gray-400 text-center">No data available.</p>
            )}
          </div>
        )}
      </div>
    </>
  );
}

export default App;
