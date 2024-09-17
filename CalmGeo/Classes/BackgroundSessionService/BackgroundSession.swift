import CoreLocation

@available(iOS 17.0, *)
public class BackgroundSession: BackgroundSessionProtocol {
  private var backgroundActivity: CLBackgroundActivitySession

  public init() {
    backgroundActivity = CLBackgroundActivitySession()
  }

  public func invalidate() {
    backgroundActivity.invalidate()
  }
}
