# SolForge + ngrok + iOS Backpack Setup

## 1️⃣ Install SolForge

```sh
curl -fsSL https://install.solforge.sh | sh
```

* Installs the SolForge binary (`solforge`) to `~/.local/bin`.
* Make sure `~/.local/bin` is in your `PATH`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

---

## 2️⃣ Start SolForge localnet

```sh
solforge run
```

* Starts a local Solana-compatible network.
* Output includes:

```
LiteSVM RPC Server running on http://0.0.0.0:8899 or localhost
LiteSVM RPC PubSub running on ws://0.0.0.0:8900 or localhost
Faucet airdropped 100000 SOL to default wallet (need to set public key)
```

* Keep this terminal open while testing.

---

## 3️⃣ Expose SolForge via ngrok

### 3a — HTTP RPC endpoint (for Backpack)

```sh
ngrok http 8899
```

* Provides a public HTTPS URL, e.g.: `https://unsplinted-seasonedly-sienna.ngrok-free.dev`
* This is the RPC URL for iOS Backpack.

### 3b — Optional TCP for WS PubSub (if needed)

```sh
ngrok tcp 8900
```

* Provides a TCP URL for WebSocket subscriptions.
* Only required if you want real-time event listening.

---

## 4️⃣ Configure Backpack iOS

* Network Name: `Localnet`
* RPC URL: `https://<ngrok-http-url>` (from step 3a)
* Chain: `Solana`
* Save → refresh balance → your 100,000 SOL should appear.

---

## ✅ Notes / Tips

* If you switch networks or restart SolForge, restart ngrok to get a new public URL.
* Kill leftover SSH/ngrok/SolForge processes if ports are busy:

```sh
pkill solforge
pkill ngrok
pkill ssh
```

* Verify the balance via CLI:

```sh
solana config set --url https://<ngrok-http-url>
solana balance <BACKPACK_PUBLIC_KEY>
```

