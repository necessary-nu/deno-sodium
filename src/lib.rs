use napi_derive::napi;

mod crypto_box;
mod utils;

pub use crypto_box::*;
pub use utils::*;

#[napi]
pub fn ensure_init() -> Result<(), napi::Error> {
    Ok(libsodium_rs::ensure_init().map_err(|e| napi::Error::from_reason(e.to_string()))?)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_github_seal_workflow() {
        // Initialize libsodium
        assert!(ensure_init().is_ok());

        // Generate a test keypair
        let keypair = generate_keypair();

        // Test message
        let message = b"Hello, GitHub!";

        // Test via calling the actual functions
        let sealed_data =
            crate::crypto_box::seal_box(message.to_vec(), keypair.public_key.to_vec())
                .unwrap();
        let decrypted = crate::crypto_box::open_sealed_box(
            sealed_data,
            keypair.public_key,
            keypair.secret_key,
        )
        .unwrap();

        assert_eq!(decrypted, message);
    }
}
