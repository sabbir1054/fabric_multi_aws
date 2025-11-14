export const checkPasswordStrength = (email: string, password: string) => {
  // Check if password is at least 8 characters long
  if (password.length < 8) {
    return {
      validity: false,
      msg: 'Password must be at least 8 characters long.',
    };
  }

  // Check if password contains any similarity with the email
  if (email.includes(password)) {
    return {
      validity: false,
      msg: 'Password cannot be similar to your email address.',
    };
  }

  // Check password strength (you can add more conditions as needed)
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasDigits = /\d/.test(password);
  const hasSpecialChars = /[!@#$%^&*(),.?":{}|<>]/.test(password);

  if (hasUpperCase && hasLowerCase && hasDigits && hasSpecialChars) {
    return { validity: true, msg: 'Password is strong.' };
  } else {
    return {
      validity: false,
      msg: 'Password is weak. It should contain at least one uppercase letter, one lowercase letter, one digit, and one special character.',
    };
  }
};
