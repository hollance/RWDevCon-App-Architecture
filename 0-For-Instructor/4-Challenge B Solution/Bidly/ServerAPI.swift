
import Foundation

/*
  This is the common access point for talking to the Bidly web service API.
  You access this object through the shared instance "serverAPI".
 */
public class ServerAPI {

  // This would normally be received as the result of logging in.
  // For this demo app, the local user is hardcoded as bidder ID 1.
  public var bidderID = 1

  //public var userName = ""
  //public var password = ""
  //public var authenticationToken = ""

  public func sendRequest(request: ServerRequest) {
    // The reason we're using this ServerAPI object to send the requests, and
    // not just have a send() method on ServerRequest, is that this object can
    // coordinate the requests. This is useful for implementing authentication.
    //
    // In pseudo-code:
    //
    // if currently waiting for authentication {
    //   put the request into a queue
    // } else if userName == "" || password == "" {
    //   put the request into a queue
    //   delegate.needToAuthenticate()
    //       the delegate will now present a modal dialog and send the user's
    //       credentials to ServerAPI.authenticate(). This sends a request to
    //       the server. When that completes successfully, the modal dialog
    //       disappears and ServerAPI will process all the requests currently
    //       in the queue
    // } else {
    //   send the request
    //   if response code is 403 (or whatever means the user is no longer authenticated) {
    //     put the request into a queue
    //     delegate.needToAuthenticate()
    //     after authentication finished, process all the requests in the queueu
    // }

    let session = NSURLSession.sharedSession()
    request.performWithSession(session)
  }
}
