import Foundation
import UIKit

// MARK: - ExportService
// Must be called on the main thread (UIGraphicsPDFRenderer requirement).

@MainActor
final class ExportService {

    // MARK: - Public: File URLs

    static func csvFileURL(from records: [InsightRecord]) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("VitalsAI_Insights.csv")
        try? csvData(from: records).write(to: url)
        return url
    }

    static func pdfFileURL(from records: [InsightRecord]) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("VitalsAI_Insights.pdf")
        try? pdfData(from: records).write(to: url)
        return url
    }

    // MARK: - CSV

    private static func csvData(from records: [InsightRecord]) -> Data {
        var lines = ["Date,Week Of,Trend,Provider,Summary,Recommendations"]
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        for r in records {
            let date     = fmt.string(from: r.createdAt)
            let week     = fmt.string(from: r.weekStartDate)
            let trend    = r.trend.capitalized
            let provider = r.providerUsed == "anthropic" ? "Anthropic Claude" : r.providerUsed
            let summary  = r.summary
                .replacingOccurrences(of: "\"", with: "'")
                .replacingOccurrences(of: "\n", with: " ")
            let recs = r.recommendations
                .map { $0.replacingOccurrences(of: "\"", with: "'") }
                .joined(separator: " | ")
            lines.append("\"\(date)\",\"\(week)\",\"\(trend)\",\"\(provider)\",\"\(summary)\",\"\(recs)\"")
        }
        return lines.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    // MARK: - PDF

    private static func pdfData(from records: [InsightRecord]) -> Data {
        let pageRect  = CGRect(x: 0, y: 0, width: 612, height: 792)   // US Letter
        let margin: CGFloat    = 48
        let contentW: CGFloat  = pageRect.width - margin * 2
        let renderer  = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 56

            // ── Title ──────────────────────────────────────────────────────
            draw("VitalsAI Health Insights",
                 at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 26, weight: .bold),
                 color: .label)
            y += 34

            draw("Generated \(Date().formatted(date: .long, time: .omitted))",
                 at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 11),
                 color: .secondaryLabel)
            y += 28

            hRule(at: y, in: pageRect, margin: margin)
            y += 22

            // ── Records ────────────────────────────────────────────────────
            let dateFmt = DateFormatter()
            dateFmt.dateStyle = .medium

            for record in records {
                // Page break if not enough room
                if y + estimatedHeight(record, width: contentW) > pageRect.height - margin {
                    ctx.beginPage()
                    y = margin
                }

                // Week header + trend pill
                draw("Week of \(dateFmt.string(from: record.weekStartDate))",
                     at: CGPoint(x: margin, y: y),
                     font: .systemFont(ofSize: 13, weight: .semibold),
                     color: .label)
                drawTrendPill(record.trend, rightEdge: pageRect.width - margin, y: y)
                y += 20

                // Provider label
                let providerLabel = record.providerUsed == "anthropic" ? "Anthropic Claude" : record.providerUsed
                draw(providerLabel,
                     at: CGPoint(x: margin, y: y),
                     font: .systemFont(ofSize: 10),
                     color: .tertiaryLabel)
                y += 18

                // Summary
                y += wrap(record.summary,
                          in: CGRect(x: margin, y: y, width: contentW, height: 300),
                          font: .systemFont(ofSize: 12),
                          color: .label)
                y += 8

                // Recommendations
                for rec in record.recommendations {
                    if y > pageRect.height - margin - 30 { ctx.beginPage(); y = margin }
                    y += wrap("• \(rec)",
                               in: CGRect(x: margin + 8, y: y, width: contentW - 8, height: 200),
                               font: .systemFont(ofSize: 11),
                               color: .secondaryLabel)
                    y += 3
                }

                y += 14
                hRule(at: y, in: pageRect, margin: margin, alpha: 0.4)
                y += 18
            }
        }
    }

    // MARK: - Drawing Helpers

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    @discardableResult
    private static func wrap(_ text: String,
                              in rect: CGRect,
                              font: UIFont,
                              color: UIColor) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let bounded = (text as NSString).boundingRect(
            with: CGSize(width: rect.width, height: rect.height),
            options: .usesLineFragmentOrigin,
            attributes: attrs,
            context: nil
        )
        (text as NSString).draw(
            in: CGRect(origin: rect.origin, size: bounded.size),
            withAttributes: attrs
        )
        return bounded.height
    }

    private static func hRule(at y: CGFloat, in pageRect: CGRect, margin: CGFloat, alpha: CGFloat = 1) {
        UIColor.separator.withAlphaComponent(alpha).setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        path.lineWidth = 0.5
        path.stroke()
    }

    private static func drawTrendPill(_ trend: String, rightEdge: CGFloat, y: CGFloat) {
        let label = trend.capitalized
        let pillFont = UIFont.systemFont(ofSize: 11, weight: .bold)
        let textSize = (label as NSString).size(withAttributes: [.font: pillFont])
        let pillW = textSize.width + 16
        let pillRect = CGRect(x: rightEdge - pillW, y: y - 1, width: pillW, height: 18)

        let color: UIColor = switch HealthTrend(rawValue: trend) {
        case .improving: .systemGreen
        case .declining: .systemRed
        default:         .systemYellow
        }

        color.withAlphaComponent(0.15).setFill()
        UIBezierPath(roundedRect: pillRect, cornerRadius: 9).fill()
        draw(label, at: CGPoint(x: pillRect.minX + 8, y: pillRect.minY + 2), font: pillFont, color: color)
    }

    private static func estimatedHeight(_ record: InsightRecord, width: CGFloat) -> CGFloat {
        let charsPerLine = Double(Int(width / 7))
        let summaryLines = ceil(Double(record.summary.count) / charsPerLine)
        let recLines = record.recommendations.reduce(0.0) { $0 + ceil(Double($1.count) / charsPerLine) }
        return CGFloat(summaryLines * 16 + recLines * 14) + 80
    }
}
