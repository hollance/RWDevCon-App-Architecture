import Foundation
import Dispatch

// This type alias makes it a bit easier to work with JSON.
typealias JSONDictionary = [String: AnyObject]

// Returns the path to the app's Documents folder.
func applicationDocumentsDirectory() -> String {
  return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first as String
}

// Performs the code from the closure after the specified number of seconds.
func afterDelay(seconds: Double, closure: () -> ()) {
  let when = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
  dispatch_after(when, dispatch_get_main_queue(), closure)
}
