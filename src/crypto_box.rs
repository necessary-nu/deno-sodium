use napi_derive::napi;

#[napi]
pub fn seal_box(message: Vec<u8>, recipient_pk: Vec<u8>) -> Result<Vec<u8>, napi::Error> {
    let public_key = libsodium_rs::crypto_box::PublicKey::from_bytes(&recipient_pk)
        .map_err(|e| napi::Error::from_reason(e.to_string()))?;
    
    libsodium_rs::crypto_box::seal_box(&message, &public_key)
        .map_err(|e| napi::Error::from_reason(e.to_string()))
}

#[napi]
pub fn open_sealed_box(
    sealed_box: Vec<u8>,
    recipient_public_key: Vec<u8>,
    recipient_secret_key: Vec<u8>,
) -> Result<Vec<u8>, napi::Error> {
    let public_key = libsodium_rs::crypto_box::PublicKey::from_bytes(&recipient_public_key)
        .map_err(|e| napi::Error::from_reason(format!("Invalid public key: {:?}", e)))?;
    
    let secret_key = libsodium_rs::crypto_box::SecretKey::from_bytes(&recipient_secret_key)
        .map_err(|e| napi::Error::from_reason(format!("Invalid secret key: {:?}", e)))?;

    libsodium_rs::crypto_box::open_sealed_box(&sealed_box, &public_key, &secret_key)
        .map_err(|e| napi::Error::from_reason(format!("Failed to open sealed box: {:?}", e)))
}

#[napi(object)]
pub struct KeyPair {
    pub public_key: Vec<u8>,
    pub secret_key: Vec<u8>,
}

#[napi]
pub fn generate_keypair() -> KeyPair {
    let keypair = libsodium_rs::crypto_box::KeyPair::generate();
    KeyPair {
        public_key: keypair.public_key.as_bytes().to_vec(),
        secret_key: keypair.secret_key.as_bytes().to_vec(),
    }
}
