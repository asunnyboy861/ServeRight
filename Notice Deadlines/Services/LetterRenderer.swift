import Foundation
import UIKit

enum LetterRenderer {
    static let disclaimer = "Disclaimer: This template provides legal information, not legal advice. Verify with your state statute."

    static func render(_ type: LetterType, ctx: [String: String]) -> String {
        let template = template(for: type)
        var out = template
        for (key, value) in ctx {
            out = out.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return out
    }

    static func template(for type: LetterType) -> String {
        switch type {
        case .rentIncrease:
            return """
            {{date}}

            {{tenant}}
            {{address}}

            RE: Notice of Rent Increase — Property at {{address}}

            Dear {{tenant}},

            This letter serves as formal notice that the monthly rent for the property located at {{address}} will increase from {{current_rent}} to {{new_rent}} per month, effective {{effective_date}}. This represents an increase of {{increase_percent}}%.

            This notice is provided in accordance with {{state_name}} law, {{statute}}.

            All other terms of your lease remain unchanged. If you have any questions, please contact the undersigned.

            Sincerely,

            {{landlord}}
            {{landlord_contact}}
            """
        case .depositItemizedReturn:
            return """
            {{date}}

            {{tenant}}
            {{forwarding_address}}

            RE: Security Deposit Return and Itemized Statement — Property at {{address}}

            Dear {{tenant}},

            Pursuant to {{state_name}} law, {{statute}}, this letter provides an itemized statement of deductions from your security deposit and the remainder being returned.

            Original deposit amount: {{deposit_amount}}
            Deductions itemized below:
            {{deductions}}

            Total deductions: {{total_deductions}}
            Amount to be returned: {{refund_amount}}

            The enclosed refund represents the balance of your security deposit. If you dispute any deduction listed above, please provide a written explanation within the statutory period.

            Sincerely,

            {{landlord}}
            {{landlord_contact}}
            """
        case .nonRenewal:
            return """
            {{date}}

            {{tenant}}
            {{address}}

            RE: Non-Renewal of Lease — Property at {{address}}

            Dear {{tenant}},

            This letter serves as notice that the lease for the property located at {{address}} will not be renewed and will terminate on {{effective_date}}. You are asked to vacate the property and return all keys by that date.

            This notice is provided in accordance with {{state_name}} law, {{statute}}, which requires at least {{notice_days}} days' notice before the end of the tenancy.

            Please schedule a move-out walkthrough and provide a forwarding address for the return of your security deposit.

            Sincerely,

            {{landlord}}
            {{landlord_contact}}
            """
        }
    }

    static func makePDF(from letterText: String) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "ServeRight Notice",
            kCGPDFContextCreator as String: "ServeRight: Notice Deadlines"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return renderer.pdfData { pdf in
            pdf.beginPage()
            let inset = pageRect.insetBy(dx: 54, dy: 54)
            let disclaimerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            (disclaimer + "\n\n").draw(in: CGRect(origin: inset.origin, size: CGSize(width: inset.width, height: 40)), withAttributes: disclaimerAttributes)
            var bodyRect = inset.offsetBy(dx: 0, dy: 44)
            bodyRect.size.height -= 44
            letterText.draw(in: bodyRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ])
        }
    }

    static func suggestedFilename(for type: LetterType, tenant: String) -> String {
        let base = type.displayName.replacingOccurrences(of: " ", with: "_")
        return "\(base)_\(tenant.replacingOccurrences(of: " ", with: "_")).pdf"
    }
}
