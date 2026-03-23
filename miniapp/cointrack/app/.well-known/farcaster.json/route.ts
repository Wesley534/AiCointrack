import { minikitConfig } from "../../../minikit.config";

// Simple manifest validator without OnchainKit dependency
function withValidManifest(config: typeof minikitConfig.miniapp) {
  return {
    version: config.version,
    imageUrl: config.heroImageUrl,
    button: {
      title: `Launch ${config.name}`,
      action: {
        name: `Launch ${config.name}`,
        type: "launch_miniapp",
      },
    },
    // Add any additional Farcaster miniapp manifest fields here
  };
}

export async function GET() {
  return Response.json(withValidManifest(minikitConfig.miniapp));
}
