import { getSecret as getSecretFromProtonPass } from '../lib/proton-pass';

export async function handleGetSecret(name: string | undefined): Promise<Response> {
  if (!name) {
    return Response.json(
      { error: 'Secret name is required' },
      { status: 400 }
    );
  }

  try {
    const value = await getSecretFromProtonPass(name);
    return Response.json({ value });
  } catch (error) {
    console.error(`Error fetching secret '${name}':`, error);
    return Response.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
