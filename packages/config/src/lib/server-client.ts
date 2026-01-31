/// <reference types="@surfingkeys-config-service/surfingkeys-types" />

const SERVER_URL = `http://${import.meta.env.VITE_SERVER_HOST}:${import.meta.env.VITE_SERVER_PORT}`;

export function getSecret(name: string): Promise<string> {
  return new Promise((resolve, reject) => {
    RUNTIME('request', {
      url: `${SERVER_URL}/api/secrets/${name}`,
      timeout: 5000
    }, response => {
      if (response.error) {
        reject(new Error(`Server error: ${response.error}`));
      } else {
        try {
          const data = JSON.parse(response.text);
          resolve(data.value);
        } catch (error) {
          reject(new Error(`Failed to parse response: ${error}`));
        }
      }
    });
  });
}
