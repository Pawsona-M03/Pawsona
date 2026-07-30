//
//  PawsonaDogDataType.swift
//  Pawsona
//
//  Created by Christianto Elvern Haryanto on 15/07/26.
//

import UniformTypeIdentifiers

extension UTType {
    /// Declared in Info.plist (`UTExportedTypeDeclarations` / `CFBundleDocumentTypes`) so
    /// AirDropped `.pawsonadog` files are routed straight into Pawsona for import.
    static let pawsonaDogData = UTType(exportedAs: "com.pawsona.dogdata")
}
