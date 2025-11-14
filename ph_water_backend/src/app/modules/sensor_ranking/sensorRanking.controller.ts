import { Request, Response } from "express";
import httpStatus from "http-status";
import catchAsync from "../../../shared/catchAsync";
import sendResponse from "../../../shared/sendResponse";
import { SensorRankingService } from "./sensorRanking.service";
// const csvUpload = catchAsync(async (req: Request, res: Response) => {
//   const result = await SensorRankingService.csvUpload(req.body.file);
//   sendResponse(res, {
//     statusCode: httpStatus.OK,
//     success: true,
//     message: "Upload done ",
//     data: result,
//   });
// });

const processCSVBatch = catchAsync(async (req: Request, res: Response) => {
  const result = await SensorRankingService.processCSVBatch(req.body.file);
  sendResponse(res, {
    statusCode: httpStatus.OK,
    success: true,
    message: "Upload done ",
    data: result,
  });
});
const getAllSensorRanks = catchAsync(async (req: Request, res: Response) => {
  const result = await SensorRankingService.getAllSensorRanks();
  sendResponse(res, {
    statusCode: httpStatus.OK,
    success: true,
    message: "retrive rank",
    data: result,
  });
});
const getSensorGraphData = catchAsync(async (req: Request, res: Response) => {
  const result = await SensorRankingService.getSensorGraphData(
    req?.params?.sensorId
  );
  sendResponse(res, {
    statusCode: httpStatus.OK,
    success: true,
    message: "sensor graph data retrieve",
    data: result,
  });
});
const getWeightPool = catchAsync(async (req: Request, res: Response) => {
  const result = await SensorRankingService.getWeightPool();
  sendResponse(res, {
    statusCode: httpStatus.OK,
    success: true,
    message: "Weight pool retrieve",
    data: result,
  });
});
const getSensorAveragesByKeyword = catchAsync(
  async (req: Request, res: Response) => {
    const result = await SensorRankingService.getSensorAveragesByKeyword(
      req?.params?.keyword
    );
    sendResponse(res, {
      statusCode: httpStatus.OK,
      success: true,
      message: "retrive graph data",
      data: result,
    });
  }
);

const getNodeActivityOverTime = catchAsync(
  async (req: Request, res: Response) => {
    const result = await SensorRankingService.getNodeActivityOverTime();
    sendResponse(res, {
      statusCode: httpStatus.OK,
      success: true,
      message: "rRetrieve node activity over the time",
      data: result,
    });
  }
);
const getWeightPoolOverTime = catchAsync(
  async (req: Request, res: Response) => {
    const result = await SensorRankingService.getWeightPoolOverTime();
    sendResponse(res, {
      statusCode: httpStatus.OK,
      success: true,
      message: "rRetrieve node activity over the time",
      data: result,
    });
  }
);
export const SensorRankingController = {
  // csvUpload,
  processCSVBatch,
  getAllSensorRanks,
  getWeightPool,
  getSensorGraphData,
  getSensorAveragesByKeyword,
  getNodeActivityOverTime,
  getWeightPoolOverTime,
};
