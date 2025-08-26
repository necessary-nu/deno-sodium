# Deno Sodium - Cross-platform build automation

# Show available commands
default:
    @just --list

# Install required tools for cross-compilation
setup:
    @echo "🔧 Installing required tools..."
    @if ! command -v zig >/dev/null 2>&1; then \
        echo "❌ Zig not found!"; \
        echo ""; \
        echo "Please install Zig for cross-compilation:"; \
        echo "  macOS:   brew install zig"; \
        echo "  Linux:   https://ziglang.org/download/"; \
        echo "  Windows: https://ziglang.org/download/"; \
        echo ""; \
        exit 1; \
    else \
        echo "✅ Zig already installed ($(zig version))"; \
    fi
    @if ! command -v cargo-zigbuild >/dev/null 2>&1; then \
        echo "📦 Installing cargo-zigbuild..."; \
        cargo install cargo-zigbuild; \
    else \
        echo "✅ cargo-zigbuild already installed"; \
    fi
    @if ! command -v napi >/dev/null 2>&1; then \
        echo "📦 Installing napi-cli..."; \
        cargo install napi-cli; \
    else \
        echo "✅ napi-cli already installed"; \
    fi
    @if ! command -v cargo-xwin >/dev/null 2>&1; then \
        echo "📦 Installing cargo-xwin for Windows cross-compilation..."; \
        cargo install cargo-xwin; \
    else \
        echo "✅ cargo-xwin already installed"; \
    fi
    @echo "✅ Setup complete!"

# Add Rust targets for cross-compilation
add-targets:
    @echo "📦 Adding Rust targets..."
    rustup target add x86_64-apple-darwin
    rustup target add aarch64-apple-darwin
    rustup target add x86_64-unknown-linux-gnu
    rustup target add aarch64-unknown-linux-gnu
    rustup target add x86_64-unknown-linux-musl
    rustup target add aarch64-unknown-linux-musl
    rustup target add x86_64-pc-windows-msvc
    # rustup target add aarch64-pc-windows-msvc
    @echo "✅ Targets added!"

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    rm -rf dist/
    @echo "✅ Clean complete!"

# Post-process generated files
post-process:
    deno run -A post.ts

# Generate JSR configuration
generate-jsr:
    @echo "📦 Generating JSR configuration..."
    @mkdir -p dist
    @VERSION=$(grep '^version = ' Cargo.toml | cut -d'"' -f2) && \
        sed "s/\%VERSION\%/${VERSION}/g" jsr.json.tpl > dist/jsr.json
    @cp README.md dist/
    @echo "✅ JSR configuration ready!"

# Run tests
test:
    @echo "🧪 Running tests..."
    cargo test

# Build for current platform (debug)
build-local:
    @echo "🔨 Building for current platform..."
    napi build --platform -o dist --esm -s
    @just post-process

# Build for current platform (release)
build-local-release:
    @echo "🚀 Building for current platform (release)..."
    napi build --platform --release -o dist --esm -s
    @just post-process

# Build for macOS x86_64
mac-x64:
    @echo "🍎 Building for macOS x86_64..."
    napi build --platform --release -o dist --esm --target x86_64-apple-darwin -s

# Build for macOS ARM64
mac-arm64:
    @echo "🍎 Building for macOS ARM64..."
    napi build --platform --release -o dist --esm --target aarch64-apple-darwin -s

# Build for Linux x86_64 (GNU)
linux-x64:
    @echo "🐧 Building for Linux x86_64 (GNU)..."
    napi build --platform --release -o dist --esm --target x86_64-unknown-linux-gnu --cross-compile -s

# Build for Linux ARM64 (GNU)  
linux-arm64:
    @echo "🐧 Building for Linux ARM64 (GNU)..."
    napi build --platform --release -o dist --esm --target aarch64-unknown-linux-gnu --cross-compile -s

# Build for Linux x86_64 (musl)
linux-x64-musl:
    @echo "🐧 Building for Linux x86_64 (musl)..."
    napi build --platform --release -o dist --esm --target x86_64-unknown-linux-musl --cross-compile -s

# Build for Linux ARM64 (musl)
linux-arm64-musl:
    @echo "🐧 Building for Linux ARM64 (musl)..."
    napi build --platform --release -o dist --esm --target aarch64-unknown-linux-musl --cross-compile -s

# Build for Windows x86_64
win-x64:
    @echo "🪟 Building for Windows x86_64..."
    napi build --platform --release -o dist --esm --target x86_64-pc-windows-msvc --cross-compile -s

# Build for Windows ARM64
# win-arm64:
#     @echo "🪟 Building for Windows ARM64..."
#     napi build --platform --release -o dist --esm --target aarch64-pc-windows-msvc --cross-compile

# Build for all macOS platforms
build-macos: mac-x64 mac-arm64
    @echo "✅ macOS builds complete!"

# Build for all Linux platforms
build-linux: linux-x64 linux-arm64 linux-x64-musl linux-arm64-musl
    @echo "✅ Linux builds complete!"

# Build for all Windows platforms
build-windows: win-x64
    @echo "✅ Windows builds complete!"

# Build for all supported platforms
build-all: setup add-targets build-macos build-linux build-windows post-process generate-jsr
    @echo "🎉 All platform builds complete!"
    @echo "📁 Output files in dist/ directory:"
    @ls -la dist/

# Run the Deno example
example:
    @echo "🦕 Running Deno example..."
    deno run --allow-read --allow-ffi --allow-env example.ts

# Development build and test cycle  
dev: build-local test example

# Build for current platform (alias)
build: build-local-release

# Show build info
info:
    @echo "ℹ️  Build Information"
    @echo "==================="
    @echo "Rust version: $(rustc --version)"
    @echo "Cargo version: $(cargo --version)"
    @echo "Node version: $(node --version)"
    @echo "Current platform: $(rustc -vV | grep host | cut -d' ' -f2)"
    @echo ""
    @echo "📋 Installed targets:"
    @rustup target list --installed | grep -E "(darwin|linux|windows)" | head -15

# Publish to JSR (requires authentication)
publish: build-all
    @echo "📢 Publishing to JSR..."
    @if ! command -v deno >/dev/null 2>&1; then \
        echo "❌ Deno not found!"; \
        echo "Install from: https://deno.land/"; \
        exit 1; \
    fi
    cd dist && deno publish -c jsr.json

# Dry run publish to JSR
publish-dry-run: build-all
    @echo "🧪 Dry run publish to JSR..."
    @if ! command -v deno >/dev/null 2>&1; then \
        echo "❌ Deno not found!"; \
        echo "Install from: https://deno.land/"; \
        exit 1; \
    fi
    cd dist && deno publish -c jsr.json --dry-run

# Create GitHub release with binaries
release-binaries: build-all
    #!/usr/bin/env bash
    set -euxo pipefail
    echo "🚀 Creating GitHub release with binaries..."
    if ! command -v gh >/dev/null 2>&1; then
        echo "❌ GitHub CLI not found!"
        echo "Install from: https://cli.github.com/"
        exit 1
    fi
    VERSION=$(grep '^version = ' Cargo.toml | cut -d'"' -f2)
    echo "Creating release for version: $VERSION"
    gh release create "v$VERSION" \
        --title "v$VERSION" \
        --notes "Release v$VERSION with native binaries for all supported platforms" \
        dist/*.node

# Full release workflow: build, create release, publish to JSR
release: release-binaries publish
    @echo "🎉 Full release complete!"