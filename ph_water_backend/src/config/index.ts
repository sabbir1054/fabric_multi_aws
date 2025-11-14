/* eslint-disable no-undef */
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.join(process.cwd(), '.env') });

export default {
  sAdminPassKey: process.env.SUPER_ADMIN_PASSKEY,
  env: process.env.NODE_ENV,
  port: process.env.PORT,
  database_url: process.env.DATABASE_URL,
  bycrypt_salt_rounds: process.env.BCRYPT_SALT_ROUNDS,
  base_url_frontend: process.env.BASE_URL_FRONTEND,
  api_link_Image: process.env.API_IMAGE_LINK,
  email_host: {
    name: process.env.EMAIL_HOST_NAME,
    port: process.env.EMAIL_HOST_PORT,
    user: process.env.EMAIL_HOST_USER,
    password: process.env.EMAIL_HOST_PASSWORD,
  },

  jwt: {
    secret: process.env.JWT_SECRET,
    refresh_secret: process.env.JWT_REFRESH_SECRET,
    expires_in: process.env.JWT_EXPIRES_IN,
    refresh_expires_in: process.env.JWT_REFRESH_EXPIRES_IN,
  },

  blockchain: {
    identityLabel: process.env.FABRIC_IDENTITY,
    connectionProfilePath: process.env.FABRIC_CONNECTION_PROFILE,
    channelName: process.env.FABRIC_CHANNEL,
    chaincodeName: process.env.FABRIC_CHAINCODE,
    mspId: process.env.MSP_ID,
  },
};
