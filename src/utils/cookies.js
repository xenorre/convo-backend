import { ENV } from "#config/env.js";

export const cookies = {
  getOptions: () => {
    const isDevTunnel =
      ENV.CLIENT_URL && ENV.CLIENT_URL.includes("devtunnels.ms");

    return {
      httpOnly: true,
      secure: ENV.NODE_ENV === "production" || isDevTunnel, // secure=true dla HTTPS dev tunnels
      sameSite: isDevTunnel || ENV.NODE_ENV === "production" ? "None" : "Lax", // None dla cross-origin HTTPS
      maxAge: 15 * 60 * 1000, // 15 minutes
      ...(isDevTunnel && { domain: undefined }), // Nie ustawiaj domain dla dev tunnels
    };
  },

  set: (res, name, value, options = {}) => {
    res.cookie(name, value, { ...cookies.getOptions(), ...options });
  },

  clear: (res, name, options = {}) => {
    res.clearCookie(name, { ...cookies.getOptions(), ...options });
  },

  get: (req, name) => {
    return req.cookies?.[name];
  },
};
