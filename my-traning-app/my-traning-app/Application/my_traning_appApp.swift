//
//  my_traning_appApp.swift
//  my-traning-app
//
//  Created by HiroakiSaito on 2025/08/31.
//

import SwiftUI

@main
struct my_traning_appApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .tint(AppColors.primary)
                .preferredColorScheme(.dark)
        }
    }
}
