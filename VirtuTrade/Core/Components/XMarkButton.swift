//
//  XMarkButton.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/28/24.
//

import SwiftUI

struct XMarkButton: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button(action: {
            dismiss()
        }, label: {
            Image(systemName: "xmark")
                .tint(.primary)
        })
    }
}

#Preview {
    XMarkButton()
}
