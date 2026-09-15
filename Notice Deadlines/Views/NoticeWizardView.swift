import SwiftUI
import SwiftData

struct NoticeWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let deadline: DeadlineInstance
    @StateObject private var purchaseManager = PurchaseManager.shared

    @State private var step = 0
    @State private var tenantName = ""
    @State private var effectiveDate = Date.now.addingTimeInterval(30 * 86400)
    @State private var letterType: LetterType = .rentIncrease
    @State private var deliveryMethod = "USPS Certified Mail"
    @State private var newRent = ""
    @State private var currentRent = ""
    @State private var deductions = ""
    @State private var generatedPDF: Data?
    @State private var showShare = false
    @State private var celebrated = false
    @AppStorage("compliance_streak") private var streak = 0

    private var jurisdiction: Jurisdiction? {
        guard let lease = deadline.lease, let property = lease.property else { return nil }
        return RuleStore.shared.jurisdiction(for: property.stateCode)
    }

    private var statuteText: String {
        guard let entry = jurisdiction?.primaryRule(for: letterType.category) else { return "state statute" }
        return entry.penalty.citation
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index <= step ? Color.accentColor : Color(.systemGray4))
                            .frame(height: 4)
                    }
                }
                .padding()

                Group {
                    switch step {
                    case 0: recipientStep
                    case 1: letterTypeStep
                    case 2: deliveryStep
                    default: exportStep
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Notice Wizard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showShare) {
                if let pdf = generatedPDF {
                    ShareSheet(items: [pdfPreview(pdf)])
                }
            }
        }
    }

    private var recipientStep: some View {
        Form {
            Section("Confirm Recipient & Effective Date") {
                TextField("Tenant name", text: $tenantName)
                DatePicker("Effective date", selection: $effectiveDate, displayedComponents: .date)
            }
            Section {
                Button {
                    step = 1
                } label: {
                    Text("Continue").frame(maxWidth: .infinity)
                }
                .disabled(tenantName.isEmpty)
            }
        }
    }

    private var letterTypeStep: some View {
        Form {
            Section("Letter Type") {
                Picker("Type", selection: $letterType) {
                    ForEach(LetterType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.inline)
            }
            Section("Letter Details") {
                if letterType == .rentIncrease {
                    TextField("Current rent (USD)", text: $currentRent)
                        .keyboardType(.decimalPad)
                    TextField("New rent (USD)", text: $newRent)
                        .keyboardType(.decimalPad)
                }
                if letterType == .depositItemizedReturn {
                    TextField("Deductions (one per line)", text: $deductions, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            Section {
                Button {
                    step = 2
                } label: {
                    Text("Continue").frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var deliveryStep: some View {
        Form {
            Section("Delivery Method") {
                Picker("Method", selection: $deliveryMethod) {
                    Text("USPS Certified Mail").tag("USPS Certified Mail")
                    Text("Hand Delivery").tag("Hand Delivery")
                    Text("Email + First Class Mail").tag("Email + First Class Mail")
                }
                .pickerStyle(.inline)
            }
            if deliveryMethod == "USPS Certified Mail" {
                Section("Certified Mail Checklist") {
                    checklistRow("Print two copies of this notice")
                    checklistRow("Attach USPS Form 3800 to the letter")
                    checklistRow("Photograph the receipt number before mailing")
                    checklistRow("Keep the green return card when it arrives")
                }
            }
            Section {
                Button {
                    generate()
                    step = 3
                } label: {
                    Text("Generate PDF").frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func checklistRow(_ text: String) -> some View {
        HStack {
            Image(systemName: "checkmark.square")
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.callout)
        }
    }

    private var exportStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                if celebrated {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce, value: celebrated)
                        Text("Served & archived")
                            .font(.title3.bold())
                        Text("Compliant streak: \(streak)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)
                }
                if let pdf = generatedPDF {
                    PDFKitView(data: pdf)
                        .frame(height: 380)
                        .cornerRadius(12)
                }
                HStack(spacing: 12) {
                    Button {
                        showShare = true
                    } label: {
                        Label("Share / Print", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button {
                        markServed()
                    } label: {
                        Text("Mark as Served")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(celebrated)
                }
                Text("PDF includes the legal-information disclaimer and \(statuteText) citation.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func generate() {
        guard let lease = deadline.lease, let property = lease.property else { return }
        let ctx: [String: String] = [
            "date": Date.now.formatted(date: .long, time: .omitted),
            "tenant": tenantName,
            "address": property.street,
            "state_name": RuleStore.shared.jurisdiction(for: property.stateCode)?.name ?? property.stateCode,
            "statute": statuteText,
            "effective_date": effectiveDate.formatted(date: .long, time: .omitted),
            "increase_percent": "\(lease.increasePercent.map { String(format: "%.1f", $0) } ?? "0")",
            "current_rent": (Double(currentRent) ?? lease.monthlyRent).formatted(.currency(code: "USD")),
            "new_rent": (Double(newRent) ?? 0).formatted(.currency(code: "USD")),
            "deposit_amount": lease.depositAmount.formatted(.currency(code: "USD")),
            "deductions": deductions.isEmpty ? "None — full refund" : deductions,
            "total_deductions": "See itemization above",
            "refund_amount": lease.depositAmount.formatted(.currency(code: "USD")),
            "forwarding_address": lease.forwardingAddressReceivedOn != nil ? "on file" : "pending",
            "notice_days": "\(deadline.resolvedDays)",
            "landlord": "Property Owner",
            "landlord_contact": "See lease"
        ]
        let text = LetterRenderer.render(letterType, ctx: ctx)
        generatedPDF = LetterRenderer.makePDF(from: text)
    }

    private func markServed() {
        guard deadline.lease != nil else { return }
        deadline.servedOn = .now
        deadline.status = .served
        RuleEngine.recomputeStatuses(modelContext: modelContext)
        let archive = LetterArchive(
            letterType: letterType,
            tenantName: tenantName,
            propertyLabel: deadline.leaseLabel,
            pdfData: generatedPDF ?? Data(),
            statuteCitation: statuteText,
            deliveryMethod: deliveryMethod
        )
        modelContext.insert(archive)
        FreeLimits.recordLetterUsed()
        streak += 1
        celebrated = true
        NotificationScheduler.rescheduleAll(deadlines: fetchAll())
        WidgetBridge.publishSnapshot(deadlines: fetchAll(), isPro: purchaseManager.isPro)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func fetchAll() -> [DeadlineInstance] {
        (try? modelContext.fetch(FetchDescriptor<DeadlineInstance>())) ?? []
    }

    private func pdfPreview(_ data: Data) -> AnyView {
        AnyView(PDFKitView(data: data))
    }
}

import PDFKit

struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.dataRepresentation() != data {
            uiView.document = PDFDocument(data: data)
        }
    }
}

import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
