import cookieParser from 'cookie-parser';
import cors from 'cors';
import express, { Application, NextFunction, Request, Response } from 'express';
import httpStatus from 'http-status';
import globalErrorHandler from './app/middlewares/globalErrorHandler';
import routes from './app/routes';
import { initFabric } from './connection';

const app: Application = express();

// Middleware setup
app.use(cors({ credentials: true }));
app.use(cookieParser());
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ limit: '20mb', extended: true }));

// Test route
app.get('/', (req: Request, res: Response) => {
  res.send('Server is running!');
});

// Initialize Fabric contract before handling requests
async function initializeFabric() {
  try {
    await initFabric();
    console.log('✅ Hyperledger Fabric initialized successfully.');
  } catch (error) {
    console.error('❌ Failed to initialize Hyperledger Fabric:', error);
  }
}
initializeFabric();

// API routes
app.use('/api/v1', routes);

// Global error handler
app.use(globalErrorHandler);

// Handle 404 - Not Found
app.use((req: Request, res: Response, next: NextFunction) => {
  res.status(httpStatus.NOT_FOUND).json({
    success: false,
    message: 'Not Found',
    errorMessages: [
      {
        path: req.originalUrl,
        message: 'API Not Found',
      },
    ],
  });
});

export default app;
