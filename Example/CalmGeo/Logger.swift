import Foundation
import os

public enum Logger {
  public static let standard: os.Logger = .init(
    subsystem: Bundle.main.bundleIdentifier!, category: LogCategory.standard.rawValue)
}

private enum LogCategory: String {
  case standard = "Standard"
}
