import CalmGeo
import Foundation

extension UserDefaults {
  func calmGeoConfig(forKey defaultName: String) -> CalmGeoConfigType? {
    guard let data = data(forKey: defaultName) else { return nil }
    do {
      return try JSONDecoder().decode(CalmGeoConfig.self, from: data)
    } catch {
      Logger.standard.error("\(error)")
      return nil
    }
  }

  func set(_ value: CalmGeoConfigType, forKey defaultName: String) {
    let data = try? JSONEncoder().encode(value)
    set(data, forKey: defaultName)
  }
}
