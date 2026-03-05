import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  webpack: (config) => {
    config.externals.push("pino-pretty", "lokijs", "encoding");
    
    // Ignore React Native async-storage which is not available in browser
    config.resolve.fallback = {
      ...config.resolve.fallback,
      "@react-native-async-storage/async-storage": false,
    };
    
    return config;
  },
};

export default nextConfig;
