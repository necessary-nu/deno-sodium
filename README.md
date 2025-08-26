# Deno Sodium

Deno bindings for libsodium-rs providing thin wrappers around the libsodium cryptographic library.

## Features

- 🔒 **Sealed Box Encryption**: Anonymous encryption using libsodium sealed boxes
- 🦕 **Deno Compatible**: Native module that works seamlessly with Deno
- ⚡ **High Performance**: Built with Rust and napi-rs for optimal performance
- 🔐 **Libsodium**: Direct wrappers around the battle-tested libsodium cryptographic library

## API

All functions are thin wrappers around libsodium-rs and match the same naming conventions.

### `ensureInit(): Promise<void>`

Initialize libsodium. Must be called before using any crypto functions.

### `sealBox(message: number[], publicKey: number[]): number[]`

Encrypt a message using sealed box encryption (anonymous encryption).

- `message`: The message to encrypt as a byte array
- `publicKey`: The recipient's public key as a byte array
- Returns: The encrypted sealed box as a byte array

### `openSealedBox(sealedBox: number[], publicKey: number[], secretKey: number[]): number[]`

Decrypt a sealed box using the recipient's key pair.

- `sealedBox`: The sealed box to decrypt as a byte array
- `publicKey`: The recipient's public key as a byte array
- `secretKey`: The recipient's secret key as a byte array
- Returns: The decrypted message as a byte array

### `generateKeypair(): KeyPair`

Generate a new key pair.

Returns: `KeyPair` object with `publicKey` and `secretKey` as byte arrays.

### `bin2Base64(data: number[]): string`

Convert binary data to base64 string.

### `base642Bin(data: string): number[]`

Convert base64 string to binary data.

## Building

```bash
# Install Rust dependencies
cargo install napi-cli

# Build for your platform
just build

# Build for all platforms (requires additional toolchains)
just build-all
```

## Usage Example

```typescript
#!/usr/bin/env deno run --allow-read --allow-ffi --allow-env

import * as sodium from "./dist/mod.ts";

// Initialize libsodium
await sodium.ensureInit();
console.log("✅ Libsodium initialized successfully");

// Generate a keypair (or use GitHub's public key)
const keypair = sodium.generateKeypair();

// Your secret to encrypt
const secret = "my-super-secret-token-12345";
const messageBytes = new TextEncoder().encode(secret);

// Encrypt using sealed box
const sealedBox = sodium.sealBox(Array.from(messageBytes), keypair.publicKey);

// For GitHub API, base64 encode the result
const encryptedBase64 = sodium.bin2Base64(sealedBox);
console.log("Encrypted data (base64):", encryptedBase64);

// Test decryption (for verification)
const decryptedBytes = sodium.openSealedBox(sealedBox, keypair.publicKey, keypair.secretKey);
const decryptedMessage = new TextDecoder().decode(new Uint8Array(decryptedBytes));
console.log("Decrypted:", decryptedMessage);
```
