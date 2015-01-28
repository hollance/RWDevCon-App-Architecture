
import Foundation
import UIKit

/*
  Most of the API consists of GET requests and a JSON response.
 */
public class ServerRequestJSON: ServerRequest {
  typealias CompletionHandler = (AnyObject?) -> Void
  private var completionHandler: CompletionHandler

  init(url: NSURL, completionHandler: CompletionHandler) {
    self.completionHandler = completionHandler
    super.init(url: url)
  }

  func parseJSON(data: NSData) -> AnyObject? {
    var error: NSError?
    if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) {
      return json
    } else if let error = error {
      println("JSON Error: \(error)")
    } else {
      println("Unknown JSON Error")
    }
    return nil
  }

  override func performWithSession(session: NSURLSession) {
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true

    dataTask = session.dataTaskWithURL(url, completionHandler: {
      data, response, error in

      self.dataTask = nil
      var results: AnyObject?

      if let error = error {
        if error.code == -999 { return }  // request was cancelled

      } else if let httpResponse = response as? NSHTTPURLResponse {
        if httpResponse.statusCode == 200 {
          results = self.parseJSON(data)
        }
      }

      dispatch_async(dispatch_get_main_queue()) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        self.completionHandler(results)
      }
    })

    dataTask?.resume()
  }
}
