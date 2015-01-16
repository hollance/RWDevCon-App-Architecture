
import Foundation

/*
  This is the (abstract) base class for all server request.
  Each type of web API request is encapsulated in its own ServerRequest subclass.
 */
public class ServerRequest {
  var dataTask: NSURLSessionDataTask?
  var url: NSURL

  public init(url: NSURL) {
    self.url = url
  }

  public func cancel() {
    dataTask?.cancel()
    dataTask = nil
  }

  func performWithSession(session: NSURLSession) {
    fatalError("subclass should implement this")
  }
}
