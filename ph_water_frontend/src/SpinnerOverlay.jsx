const SpinnerOverlay = () => {
  return (
    <div className="fixed top-1/2 left-1/2 z-50 -translate-x-1/2 -translate-y-1/2">
      <div className="bg-[#1e1e2f] px-6 py-5 rounded-xl shadow-xl text-center text-white w-72 border border-[#0e7673]">
        <h2 className="text-lg font-semibold mb-4">Processing...</h2>

        <div className="flex flex-col items-center gap-3">
          <div
            className="w-10 h-10 border-4 rounded-full animate-spin"
            style={{
              borderColor: "#0e7673",
              borderTopColor: "transparent",
            }}
          ></div>
          <p className="text-sm text-gray-300">
            Data is processing,it take time please wait. You can see backend log
            in the terminal.
          </p>
        </div>
      </div>
    </div>
  );
};

export default SpinnerOverlay;
