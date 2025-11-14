/* eslint-disable @typescript-eslint/no-unused-vars */

import { createTransport } from 'nodemailer';
import config from '../config';
const hostPort = config.email_host.name;
const transporterOptions = {
  host: config.email_host.name,
  port: Number(hostPort),
  secure: true,
  auth: {
    user: `${config.email_host.user}`,
    pass: `${config.email_host.password}`,
  },
};

export const transporter = createTransport(transporterOptions);

export type IEmailInfo = {
  from: string;
  to: string;
  subject: string;
  text: string;
  html: string;
};

export const sentEmail = async (payload: IEmailInfo) => {
  const info = await transporter.sendMail(payload);
  return info;
};
