import { signInSchema, signUpSchema } from "#validations/auth.validation.js";
import { formatValidationError } from "#utils/format.js";
import { authenticateUser, createUser } from "#services/auth.service.js";
import { jwttoken } from "#utils/jwt.js";
import { cookies } from "#utils/cookies.js";
import { sendWelcomeEmail } from "#src/services/email.service.js";
import { ENV } from "#config/env.js";
import logger from "#config/logger.js";

export const signUp = async (req, res, next) => {
  try {
    const validationResult = signUpSchema.safeParse(req.body);

    if (!validationResult.success) {
      return res.status(400).json({
        error: "Validation failed",
        details: formatValidationError(validationResult.error),
      });
    }

    const { fullName, email, password } = validationResult.data;

    const user = await createUser({ fullName, email, password });

    if (user) {
      const token = jwttoken.sign({
        id: user.id,
        fullName: user.fullName,
        email: user.email,
      });
      cookies.set(res, "token", token);
    } else {
      return res.status(400).json({ error: "Unable to create user" });
    }

    res.status(201).json({
      message: "User registered successfully",
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
      },
    });

    await sendWelcomeEmail(user.email, user.fullName, ENV.CLIENT_URL);
  } catch (e) {
    // Check if it's a duplicate email error
    if (e.message === "Email already in use") {
      return res.status(409).json({ error: "Email already in use" });
    }

    logger.error("Error in signUp:", e);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const login = async (req, res) => {
  try {
    const validationResult = signInSchema.safeParse(req.body);

    if (!validationResult.success) {
      return res.status(400).json({
        error: "Validation failed",
        details: formatValidationError(validationResult.error),
      });
    }

    const { email, password } = validationResult.data;
    const user = await authenticateUser({ email, password });

    if (!user) {
      return res.status(500).json({ error: "Unable to authenticate user" });
    }

    const token = jwttoken.sign({
      id: user.id,
      fullName: user.fullName,
      email: user.email,
    });

    cookies.set(res, "token", token);

    res.status(200).json({
      message: "User logged in successfully",
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
      },
    });
  } catch (e) {
    // Check if it's an authentication error (invalid credentials)
    if (e.message === "Invalid email or password") {
      return res.status(401).json({ error: "Invalid email or password" });
    }

    // For other errors, return generic message
    res.status(500).json({ error: "Internal server error" });
  }
};

export const logout = async (req, res) => {
  try {
    // Get the current user's email from token for logging (optional)
    const token = cookies.get(req, "token");
    let userEmail = "unknown";

    if (token) {
      try {
        const decoded = jwttoken.verify(token);
        userEmail = decoded.email;
      } catch (tokenError) {
        // Token might be invalid, but we can still proceed with logout
        logger.warn("Invalid token during sign-out:", tokenError.message);
      }
    }

    // Clear the authentication cookie
    cookies.clear(res, "token");

    logger.info(`User signed out successfully: ${userEmail}`);
    res.status(200).json({
      message: "User signed out successfully",
    });
  } catch (e) {
    logger.error("Error during sign-out:", e);
    res.status(500).json({ error: "Internal server error" });
  }
};
