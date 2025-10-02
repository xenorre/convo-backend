import logger from "#config/logger.js";
import bcrypt from "bcrypt";
import User from "#src/models/user.model.js";

export const hashPassword = async (password) => {
  try {
    const salt = await bcrypt.genSalt(10);
    return await bcrypt.hash(password, salt);
  } catch (e) {
    logger.error(`Error hashing password: ${e}`);
    throw new Error("Error hashing password");
  }
};

export const createUser = async ({ fullName, email, password }) => {
  try {
    const userExists = await User.findOne({ email });

    if (userExists) {
      throw new Error("Email already in use");
    }

    const hashedPassword = await hashPassword(password);

    const newUser = new User({
      fullName,
      email,
      password: hashedPassword,
    });

    await newUser.save();
    logger.info(`User ${newUser.email} created successfully`);
    return newUser;
  } catch (e) {
    logger.error(`Error creating user: ${e}`);
    throw e;
  }
};
