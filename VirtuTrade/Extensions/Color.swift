//
//  Color.swift
//  VirtuTrade
//
//  Created by Jasin ‎ on 10/17/24.
//

import Foundation
import SwiftUI

extension Color {
    
    static let theme = ColorTheme()
    static let launch = LaunchTheme()
    
}

struct ColorTheme {
    
    let accent = Color("AccentColor")
    let accentTwo = Color("SecondAccentColor")
    let background = Color("BackgroundColor")
    let green = Color("myGreen")
    let red = Color("myRed")
    let secondaryText = Color("SecondaryTextColor")
    
}

struct ColorTheme2 {
    let accent = Color("AccentColor")
    let accentTwo = Color("SecondAccentColor")
    let background = Color("BackgroundColor")
    let green = Color("myGreen")
    let red = Color("myRed")
    let secondaryText = Color("SecondaryTextColor")
}

struct LaunchTheme {
    
    let accent = Color("LaunchAccentColor")
    let background = Color("LaunchBackgroundColor")
    
}
