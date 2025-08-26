use napi_derive::napi;

#[napi]
pub fn bin2base64(data: Vec<u8>) -> String {
    libsodium_rs::utils::bin2base64(&data, libsodium_rs::utils::BASE64_VARIANT_ORIGINAL)
}

#[napi]
pub fn base642bin(data: String) -> Result<Vec<u8>, napi::Error> {
    Ok(
        libsodium_rs::utils::base642bin(&data, libsodium_rs::utils::BASE64_VARIANT_ORIGINAL)
            .map_err(|e| napi::Error::from_reason(e.to_string()))?,
    )
}
