#!/usr/bin/env deno run --allow-read --allow-ffi --allow-env

// Import the native module
import * as sodium from "./dist/mod.ts";

console.log("🧂 Deno Sodium - GitHub Secret Encryption Example\n");

// Generate a keypair (simulating GitHub's public key)
console.log("\n🔑 Generating keypair...");
const keypair = sodium.generateKeypair();
console.log("Public key (bytes):", keypair.publicKey.length);
console.log("Secret key (bytes):", keypair.secretKey.length);

// Secret message to encrypt (this would be your GitHub secret)
const secretMessage = "my-super-secret-token-12345";
const messageBytes = new TextEncoder().encode(secretMessage);

console.log(`\n🔒 Encrypting secret: "${secretMessage}"`);

try {
  // Encrypt using raw libsodium seal_box
  const sealedBox = sodium.sealBox(Array.from(messageBytes), keypair.publicKey);
  console.log("✅ Encryption successful!");
  
  // For GitHub API, we need to base64 encode the result
  const encryptedBase64 = sodium.bin2Base64(sealedBox);
  console.log("Encrypted data (base64):", encryptedBase64);
  
  console.log("\n📤 This encrypted string can now be sent to GitHub's secrets API");
  
  // Test decryption (for verification only - GitHub handles this)
  console.log("\n🔓 Testing decryption (for verification)...");
  try {
    const decryptedBytes = sodium.openSealedBox(sealedBox, keypair.publicKey, keypair.secretKey);
    const decryptedMessage = new TextDecoder().decode(new Uint8Array(decryptedBytes));
    console.log("✅ Decryption successful!");
    console.log("Decrypted message:", decryptedMessage);
    console.log("✅ Original message matches:", decryptedMessage === secretMessage);
  } catch (error) {
    if (error instanceof Error) {
      console.error("❌ Decryption failed:", error.message);
    } else {
      console.error("❌ Decryption failed with unknown error");
    }
    // @ts-ignore
    Deno.exit(1);
  }
} catch (error) {
  if (error instanceof Error) {
    console.error("❌ Encryption failed:", error.message);
  } else {
    console.error("❌ Encryption failed with unknown error");
  }
  // @ts-ignore
  Deno.exit(1);
}

console.log("\n🎉 Example completed!");
console.log("\n📚 GitHub Integration Workflow:");
console.log("1. Get repository public key: GET /repos/:owner/:repo/actions/secrets/public-key");  
console.log("2. const publicKey = sodium.base642Bin(response.key);");
console.log("3. const sealed = sodium.sealBox(secretBytes, publicKey);");
console.log("4. const encrypted = sodium.bin2Base64(sealed);");
console.log("5. Send encrypted to: PUT /repos/:owner/:repo/actions/secrets/:secret_name");