import fs from 'fs';
import httpStatus from 'http-status';
import path from 'path';
import Tesseract from 'tesseract.js';
import ApiError from '../errors/ApiError';

// Function to extract text from an image
export const extractText = async (image: string) => {
  try {
    // Ensure the image path is absolute
    const imagePath = path.isAbsolute(image) ? image : path.resolve(image);
    // console.log(`Processing Image: ${imagePath}`);

    // Check if the file is accessible
    await fs.promises.access(imagePath, fs.constants.R_OK);
    // console.log('File is accessible, proceeding...');

    // Perform OCR using Tesseract.js
    const {
      data: { text },
    } = await Tesseract.recognize(imagePath, 'eng');

    // Extract required fields using regex
    const certificateIDMatch = text.match(/Certificate ID:\s*([A-Za-z0-9-]+)/);
    const studentNameMatch = text.match(
      /This is to certify that\s*(.+?)\s*has successfully/,
    );
    const universityMatch = text.match(/(.*) University/);
    const departmentMatch = text.match(/Department of (.+)/);
    const courseMatch = text.match(
      /completed the course\s*([\w\s]+)\s*in the Department/,
    );
    const cgpaMatch = text.match(/CGPA of\s*([\d.]+)/);
    const issueDateMatch = text.match(/Issued on:\s*([\d-]+)/);

    const certificateData = {
      certificateID: certificateIDMatch ? certificateIDMatch[1] : null,
      studentName: studentNameMatch ? studentNameMatch[1].trim() : null,
      university: universityMatch
        ? `${universityMatch[1].trim()} University`
        : null,
      department: departmentMatch ? departmentMatch[1].trim() : null,
      course: courseMatch ? courseMatch[1].trim() : null,
      cgpa: cgpaMatch ? parseFloat(cgpaMatch[1]) : null,
      issueDate: issueDateMatch ? issueDateMatch[1] : null,
    };
   
    return certificateData;
  } catch (error: any) {
    throw new ApiError(httpStatus.NOT_FOUND, 'Certificate not found ');
  }
};
