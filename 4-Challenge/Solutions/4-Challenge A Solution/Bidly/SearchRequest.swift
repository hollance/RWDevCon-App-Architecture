
import Foundation

class SearchRequest: ServerRequestJSON {
  init(searchText: String, completionHandler: CompletionHandler) {
    let escapedSearchText = searchText.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    let urlString = String(format: "http://api.bid.ly/v1/search?q=%@", escapedSearchText)
    let url = NSURL(string: urlString)!
    super.init(url: url, completionHandler: completionHandler)
  }
}
