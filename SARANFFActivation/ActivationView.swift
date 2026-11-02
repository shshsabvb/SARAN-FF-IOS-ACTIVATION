import SwiftUI
import UIKit

struct ActivationView: View {
    @State private var key = ""
    @State private var message = "Enter your activation key to continue."
    @State private var isLoading = false
    @State private var isActivated = false

    private let activationURL = URL(string: "https://saran-ff-api.onrender.com/activate")!

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.035, green: 0.055, blue: 0.12), Color(red: 0.10, green: 0.12, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("SARAN FF")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("ACTIVATION REQUIRED")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activation key")
                        .font(.headline)
                        .foregroundStyle(.white)
                    TextField("Enter your key", text: $key)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(16)
                        .background(.white.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                        .tint(.cyan)
                    Button(action: activate) {
                        HStack {
                            if isLoading { ProgressView().tint(.black) }
                            Text(isLoading ? "CHECKING..." : "ACTIVATE")
                                .fontWeight(.heavy)
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.cyan)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isLoading || key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(isActivated ? .green : .white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(22)
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                Spacer()
                Text("Internet connection required for verification")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 18)
            }
            .padding(.horizontal, 24)
        }
    }

    private func activate() {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else { return }
        isLoading = true
        message = "Contacting activation server…"
        var request = URLRequest(url: activationURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let device = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["key": cleanKey, "device": device])
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    message = "Unable to contact server: \(error.localizedDescription)"
                    return
                }
                guard let http = response as? HTTPURLResponse, let data = data else {
                    message = "No response from activation server. Please try again."
                    return
                }
                let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
                let detail = payload["detail"] as? String ?? payload["message"] as? String
                if (200...299).contains(http.statusCode) {
                    isActivated = true
                    message = detail ?? "Activation successful."
                } else {
                    isActivated = false
                    message = detail ?? "Invalid, expired, or revoked key."
                }
            }
        }.resume()
    }
}
