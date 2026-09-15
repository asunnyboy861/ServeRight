import SwiftUI

struct ContactSupportView: View {
    @State private var subject = "General"
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var successBanner = false
    @State private var errorMessage: String?

    private let backendURL = URL(string: "https://feedback-board.iocompile67692.workers.dev/api/feedback")!
    private let maxMessageLength = 1000

    private let subjects: [(String, String)] = [
        ("General", "bubble.left.fill"),
        ("Feature Suggestion", "lightbulb.fill"),
        ("Bug Report", "ant.fill"),
        ("Usage Question", "questionmark.circle.fill"),
        ("Performance Issue", "gauge.with.dots.needle.67percent"),
        ("UI Improvement", "paintpalette.fill"),
        ("Other", "ellipsis.circle.fill")
    ]

    private var emailValid: Bool {
        email.contains("@") && email.contains(".") && !email.hasPrefix("@") && !email.hasSuffix(".")
    }

    private var canSubmit: Bool {
        !name.isEmpty && emailValid && !message.isEmpty && (subject != "Other" || !customSubject.isEmpty)
    }

    var body: some View {
        Form {
            Section("What's it about?") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(subjects, id: \.0) { option in
                        subjectTile(option.0, icon: option.1)
                    }
                }
                .buttonStyle(.plain)
                if subject == "Other" {
                    TextField("Custom subject", text: $customSubject)
                }
            }

            Section {
                TextField("Your name", text: $name)
                TextField("yourname@example.com", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !email.isEmpty && !emailValid {
                    Text("Please enter a valid email address.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Your Details")
            }

            Section {
                TextEditor(text: $message)
                    .frame(minHeight: 120)
                    .onChange(of: message) {
                        if message.count > maxMessageLength {
                            message = String(message.prefix(maxMessageLength))
                        }
                    }
                HStack {
                    Spacer()
                    Text("\(message.count) / \(maxMessageLength)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } header: {
                Text("Message")
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Submit")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                }
                .disabled(!canSubmit || isSubmitting)
            }

            Section {
                Text("We only use your email to respond to this feedback.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Something went wrong", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .overlay(alignment: .top) {
            if successBanner {
                VStack {
                    Label("Thank you! Your feedback has been sent.", systemImage: "checkmark.circle.fill")
                        .padding()
                        .background(.green.opacity(0.9), in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func subjectTile(_ title: String, icon: String) -> some View {
        let isSelected = subject == title
        return Button {
            subject = title
        } label: {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : icon)
                    .font(.title3)
                Text(title)
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : Color(.separator), lineWidth: 1)
            )
        }
        .accessibilityLabel("Subject: \(title)")
    }

    private func submit() async {
        isSubmitting = true
        let finalSubject = subject == "Other" ? customSubject : subject
        let payload = FeedbackRequest(
            name: name,
            email: email,
            subject: finalSubject,
            message: message,
            app_name: "ServeRight: Notice Deadlines"
        )
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(payload)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                withAnimation {
                    successBanner = true
                }
                name = ""; email = ""; message = ""; customSubject = ""; subject = "General"
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                withAnimation {
                    successBanner = false
                }
            } else {
                let text = String(data: data, encoding: .utf8) ?? ""
                errorMessage = text.isEmpty ? "Please try again." : text
            }
        } catch {
            errorMessage = "Network error. Please try again."
        }
        isSubmitting = false
    }
}

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}
