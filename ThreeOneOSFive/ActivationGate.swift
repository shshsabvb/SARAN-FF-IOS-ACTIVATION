import SwiftUI
import UIKit

private struct ActivationResponse: Decodable {
    let valid: Bool
    let message: String
    let expires: String
}

@MainActor
private final class ActivationModel: ObservableObject {
    @Published var isActivated = false
    @Published var key = ""
    @Published var message = "Enter your activation key to continue."
    @Published var isLoading = false

    init() {
        if let saved = UserDefaults.standard.string(forKey: "saran_ff_saved_key") {
            key = saved
            activate()
        }
    }

    private let endpoint = URL(string: "https://saran-ff-api.onrender.com/activate")!
    private let deviceID: String = {
        let defaults = UserDefaults.standard
        let storageKey = "saran_ff_device_id"
        if let saved = defaults.string(forKey: storageKey) { return saved }
        let value = UUID().uuidString
        defaults.set(value, forKey: storageKey)
        return value
    }()

    func activate() {
        let cleaned = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { message = "Please enter your activation key."; return }
        isLoading = true
        message = "Checking your key…"
        Task {
            defer { isLoading = false }
            do {
                var request = URLRequest(url: endpoint)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 25
                request.httpBody = try JSONSerialization.data(withJSONObject: ["key": cleaned, "device": deviceID])
                let (data, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if status == 200 {
                    let result = try JSONDecoder().decode(ActivationResponse.self, from: data)
                    guard result.valid else { message = "Activation was not approved."; return }
                    UserDefaults.standard.set(cleaned, forKey: "saran_ff_saved_key")
                    isActivated = true
                    message = "Activation successful."
                } else {
                    let detail = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                    message = detail?["detail"] as? String ?? "Activation failed. Please check your key."
                }
            } catch {
                message = "Could not contact the activation server. Check your internet connection and try again."
            }
        }
    }
}

struct ActivationGateView<Content: View>: View {
    @StateObject private var model = ActivationModel()
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if model.isActivated {
                content()
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 58)).foregroundStyle(.red)
                        Text("SARAN FF")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("ACTIVATION REQUIRED")
                            .font(.headline).tracking(2).foregroundStyle(.white.opacity(0.75))
                        TextField("Enter activation key", text: $model.key)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(16)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2)))
                        Button(action: model.activate) {
                            HStack {
                                if model.isLoading { ProgressView().tint(.white) }
                                Text(model.isLoading ? "CHECKING…" : "ACTIVATE")
                                    .fontWeight(.bold).tracking(1)
                            }
                            .frame(maxWidth: .infinity).padding(16)
                            .background(Color.red).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(model.isLoading)
                        Text(model.message)
                            .font(.footnote).foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                        Spacer()
                        Text("An active internet connection is required.")
                            .font(.caption).foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(28)
                }
            }
        }
    }
}
