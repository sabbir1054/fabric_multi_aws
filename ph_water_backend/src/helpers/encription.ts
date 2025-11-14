import bcrypt from 'bcrypt';
import config from '../config';
export const encryptPassword = (password: string) => {
  const result = bcrypt.hash(password, Number(config.bycrypt_salt_rounds));
  return result;
};

export const isPasswordMatched = (
  givenPassword: string,
  savedPassword: string
) => {
  const result = bcrypt.compare(givenPassword, savedPassword);
  return result;
};
