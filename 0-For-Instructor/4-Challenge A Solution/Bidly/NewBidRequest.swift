
import Foundation
import UIKit

class NewBidRequest: ServerRequestJSON {
  init(itemID: Int, bidderID: Int, amount: String, completionHandler: CompletionHandler) {
    let urlString = String(format: "http://api.bid.ly/v1/bid?itemID=%d&bidderID=%d&amount=%@", itemID, bidderID, amount)
    let url = NSURL(string: urlString)!
    super.init(url: url, completionHandler: completionHandler)
  }
}
