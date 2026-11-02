# SARAN FF Activation App

A standalone SwiftUI activation-screen app. It validates keys by POSTing JSON `{ "key": "...", "device": "..." }` to `https://saran-ff-api.onrender.com/activate`.

## Build
Codemagic reads `codemagic.yaml` from the repository root. The workflow builds an unsigned app and packages it as an IPA for signing with a compatible signing service such as ESign.

This is an activation-only app; it does not contain or launch the original app. The activation server must return HTTP 2xx for accepted keys. Test the response format and app behavior before distributing.
