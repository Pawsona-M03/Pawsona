//
//  PDFGenerator.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import SwiftUI

enum PDFGenerator {
    static func generate(from dogs: [Dog]) -> Data? {
        let renderer = ImageRenderer(content: DogPDFReportView(dogs: dogs))
        renderer.proposedSize = ProposedViewSize(width: DogPDFReportView.pageWidth, height: nil)

        guard let consumerData = CFDataCreateMutable(nil, 0),
              let consumer = CGDataConsumer(data: consumerData) else {
            return nil
        }

        renderer.render { size, renderContent in
            var mediaBox = CGRect(origin: .zero, size: size)

            guard let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
                return
            }

            pdfContext.beginPDFPage(nil)
            renderContent(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }

        return consumerData as Data
    }
}
