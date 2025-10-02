import logger from "#config/logger.js";
import { signUpSchema } from "#validations/auth.validation.js";
import { formatValidationError } from "#utils/format.js";
import { createUser } from "#services/auth.service.js";
import { jwttoken } from "#utils/jwt.js";
import { cookies } from "#utils/cookies.js";

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
      message: "User registered",
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
      },
    });
  } catch (e) {
    res.status(500).json({ error: "Internal server error" });
  }
};
