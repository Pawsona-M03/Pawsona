//
//  ShareSheet.swift
//  Pawsona
//
//  A `UIActivityViewController` wrapper. `ShareLink` covers the inline case,
//  but it needs its item up front — and building ours means rendering a PDF or
//  base64-ing a photo, which is too expensive to do before the user has asked
//  to share. SwiftUI has no way to present the share sheet programmatically,
//  so this is the gap it fills.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let fileURL: URL
    let previewTitle: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [ShareSheetItemSource(fileURL: fileURL, previewTitle: previewTitle)],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Supplies the file plus a human title, so AirDrop and Messages show the dog's
/// name rather than the raw file name.
private final class ShareSheetItemSource: NSObject, UIActivityItemSource {
    private let fileURL: URL
    private let previewTitle: String

    init(fileURL: URL, previewTitle: String) {
        self.fileURL = fileURL
        self.previewTitle = previewTitle
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any {
        fileURL
    }

    func activityViewController(
        _ controller: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        fileURL
    }

    func activityViewController(
        _ controller: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        previewTitle
    }
}
