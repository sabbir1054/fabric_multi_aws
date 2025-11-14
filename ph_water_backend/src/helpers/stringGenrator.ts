export const randomString = () => {
  return Math.random().toString(36).substring(2, 15);
};

export const otpGenerator = () => {
  let otp = '';
  for (let i = 0; i < 5; i++) {
    otp += Math.floor(Math.random() * 10);
  }
  return otp;
};
