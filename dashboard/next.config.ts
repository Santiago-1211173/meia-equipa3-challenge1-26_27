import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  allowedDevOrigins: [
    "challenge1.smbitsolutions.pt",
    "*.smbitsolutions.pt",
    "localhost:3000",
  ],
};

export default nextConfig;
