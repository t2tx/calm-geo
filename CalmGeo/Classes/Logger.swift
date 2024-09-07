import Foundation
import os

public enum Logger {
  @available(iOS 14.0, *)
  public static let standard: os.Logger = .init(
    subsystem: Bundle.main.bundleIdentifier!, category: LogCategory.standard.rawValue)
}

private enum LogCategory: String {
  case standard = "Standard"
}
