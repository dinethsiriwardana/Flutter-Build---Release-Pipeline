# Guide to Setting Up iOS Secrets for GitHub Actions

Since GitHub Action runners start fresh every time, they don't have your Xcode credentials. We need to manually provide the Apple certificates and provisioning profiles as GitHub Secrets.

Here is the step-by-step process for getting each of the 7 new secrets. 

*(Note: `ENV_FILE` is already set up from your Android workflow, so we skip it here!)*

---

### Step 1: Create & Export your Apple Distribution Certificate (`.p12`)
This certificate proves you are authorized to build the app for production.

> **Note:** If you already have an `Apple Distribution` cert visible under `My Certificates` in Keychain Access (with a private key arrow), you can skip to sub-step 7 and export it directly. If not (e.g. the limit is reached or it was created on another machine), follow the full CLI flow below.

#### Option A — Full CLI Flow (when cert doesn't exist locally)

**1a. Generate a CSR and private key on your Mac:**
```bash
openssl req -nodes -newkey rsa:2048 \
  -keyout ~/Downloads/distribution.key \
  -out ~/Downloads/distribution.csr \
  -subj "/emailAddress=YOUR@EMAIL.com/CN=App Distribution/C=US"
```

**1b. Upload the CSR to Apple Developer Portal:**
1. Go to [developer.apple.com/account/resources/certificates/list](https://developer.apple.com/account/resources/certificates/list)
2. If the `+` button says **"Maximum number of certificates generated"**, revoke one of the existing API Key Distribution certs (safe to revoke — they are auto-managed)
3. Click `+` → select **Apple Distribution** → **Continue**
4. Upload `~/Downloads/distribution.csr` → **Continue** → **Download**
5. Save the downloaded `.cer` file to `~/Downloads/distribution.cer`

**1c. Convert the `.cer` + `.key` into a `.p12` bundle:**
```bash
# Convert .cer to PEM
openssl x509 -in ~/Downloads/distribution.cer -inform DER \
  -out ~/Downloads/distribution.pem -outform PEM

# Bundle .pem + private key into a .p12
# Choose your own password — it becomes P12_PASSWORD
openssl pkcs12 -export \
  -out ~/Downloads/distribution.p12 \
  -inkey ~/Downloads/distribution.key \
  -in ~/Downloads/distribution.pem \
  -name "Apple Distribution: Equine Network, LLC" \
  -passout pass:YOUR_CHOSEN_PASSWORD
```

**1d. Base64 encode the `.p12` and copy to clipboard:**
```bash
base64 -i ~/Downloads/distribution.p12 | pbcopy
```
- **The clipboard contents become your `BUILD_CERTIFICATE_BASE64` secret.**
- **The password you chose above becomes your `P12_PASSWORD` secret.**

#### Option B — Keychain Export (if cert already exists locally)
1. Open **Keychain Access** → **My Certificates**
2. Find **"Apple Distribution: Equine Network, LLC"** (must have a ▶ arrow showing the private key)
3. Right-click the certificate → **Export** → save as `distribution.p12` → set a password
4. Run:
   ```bash
   base64 -i ~/Downloads/distribution.p12 | pbcopy
   ```
   - **Clipboard = `BUILD_CERTIFICATE_BASE64`**, password = **`P12_PASSWORD`**

---

### Step 2: Download your Provisioning Profile (`.mobileprovision`)
This file tells Apple that your app ID is allowed to be signed by the certificate above.

1. Log into your [Apple Developer Account](https://developer.apple.com/account/).
2. Go to **Certificates, Identifiers & Profiles**.
3. Click on **Profiles** on the left sidebar.
4. Find the **App Store** (Distribution) profile for your app's bundle ID. 
   
   > [!IMPORTANT]
   > **Certificate Linkage:** Ensure the profile is linked to the **correct, active Distribution Certificate** (the one from Step 1). 
   > - If you generated a *new* certificate to replace an old/expired one (e.g., changing from an older cert to a newly generated one expiring in July 2027), you must edit the existing profile, **uncheck the old certificate**, **check the new certificate**, click **Save**, and then download the new profile. 
   > - If this is not done, Xcode will fail with a mismatch error (i.e., the profile will not recognize the new signing certificate).

5. Click **Download** and save the `.mobileprovision` file to your Desktop.
6. Open your Terminal and run this command to convert it to Base64:
    ```bash
    base64 -i ~/Desktop/YourProfile.mobileprovision -o ~/Desktop/Profile_Base64.txt
    ```
7. Open `Profile_Base64.txt`. Copy the ENTIRE block of text.
    - **This text becomes your `BUILD_PROVISION_PROFILE_BASE64` secret.**

---

### Step 3: Generate an App Store Connect API Key (`.p8`)
This allows the GitHub Action to upload the built `.ipa` directly to TestFlight without needing 2-Factor Authentication (SMS).

1. Log into [App Store Connect](https://appstoreconnect.apple.com/).
2. Go to **Users and Access**, then click the **Integrations** tab at the top.
3. Click on **App Store Connect API** on the left sidebar.
4. If you haven't requested access to the API yet, do so. Otherwise, click the **`+`** button to generate a new key.
5. Name it something like `GitHub Actions CI` and give it the **App Manager** role.
6. Once created, you will see a table with your new key.
7. Note the **Issuer ID** at the top of the page.
   - **This becomes your `APPSTORE_ISSUER_ID` secret.**
8. Note the **Key ID** in the row of the key you just made.
   - **This becomes your `APPSTORE_API_KEY_ID` secret.**
9. Click **Download API Key**. (You can only do this once!). It will download an `.p8` file.
10. Open the `.p8` file in a text editor (like VS Code or TextEdit). Copy ALL the contents, including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`.
    - **This text becomes your `APPSTORE_API_PRIVATE_KEY` secret.**

---

### Step 4: Add them all to GitHub

1. Go to your GitHub Repository in your browser.
2. Go to **Settings** > **Secrets and variables** > **Actions**.
3. Click **New repository secret** and add them one by one:

| Secret Name | What to put in the value box |
| :--- | :--- |
| `BUILD_CERTIFICATE_BASE64` | Output of `base64 -i ~/Downloads/distribution.p12 \| pbcopy` (paste from clipboard) |
| `P12_PASSWORD` | The password you used with `-passout pass:YOUR_CHOSEN_PASSWORD` when creating the `.p12` |
| `BUILD_PROVISION_PROFILE_BASE64` | The giant text block from `Profile_Base64.txt` |
| `KEYCHAIN_PASSWORD` | Type any random password like `github123` (the runner needs this to unlock the temporary keychain) |
| `APPSTORE_ISSUER_ID` | The Issuer ID from App Store Connect |
| `APPSTORE_API_KEY_ID` | The Key ID from App Store Connect |
| `APPSTORE_API_PRIVATE_KEY` | The exact contents of the `.p8` file |

You're done! Once these 7 secrets are added, any push to `release` will successfully build the app and push it straight to TestFlight.
