import { Resend } from "resend";
import { ENV } from "#config/env.js";

export const resendClient = new Resend(ENV.RESEND_API_KEY);
