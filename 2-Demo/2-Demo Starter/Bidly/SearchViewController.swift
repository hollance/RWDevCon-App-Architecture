
import UIKit

class SearchViewController: UITableViewController, UISearchBarDelegate {

  var watchlist: Watchlist!

  @IBOutlet weak var searchBar: UISearchBar!

  private var loading = false  // to show the spinner
  
  private lazy var currencyFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencyCode = "USD"
    return formatter
  }()

  private var searchResults = [Item]()

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
  }

  // MARK: Search Bar

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    searchBar.resignFirstResponder()
  }

  func searchBarSearchButtonClicked(searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    search(searchBar.text)
  }

  // MARK: Segues

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ItemDetail" {
      if let indexPath = tableView.indexPathForCell(sender as UITableViewCell) {
        let item = searchResults[indexPath.row]
        let controller = segue.destinationViewController as ItemDetailViewController
        controller.item = item
        controller.watchlist = watchlist
      }
    }
  }

  // MARK: Table View Data Source

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if loading {
      return 1
    } else {
      return searchResults.count
    }
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if loading {
      let cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath) as UITableViewCell
      if let spinner = cell.viewWithTag(100) as? UIActivityIndicatorView {
        spinner.startAnimating()
      }
      return cell

    } else {
      let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell", forIndexPath: indexPath) as ItemCell
      let item = searchResults[indexPath.row]

      var highestBidAmount = 0.0
      for bid in item.bids {
        highestBidAmount = max(bid.amount, highestBidAmount)
      }

      cell.itemNameLabel.text = item.itemName

      if item.bids.count == 1 {
        cell.bidderCountLabel.text = "1 Bidder"
      } else {
        cell.bidderCountLabel.text = "\(item.bids.count) Bidders"
      }

      cell.highestBidLabel.text = currencyFormatter.stringFromNumber(highestBidAmount)
      return cell
    }
  }

  // MARK: Networking

  private var dataTask: NSURLSessionDataTask? = nil

  private func search(searchText: String) {
    dataTask?.cancel()

    loading = true
    tableView.reloadData()

    UIApplication.sharedApplication().networkActivityIndicatorVisible = true

    let escapedSearchText = searchText.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    let urlString = String(format: "http://api.bid.ly/v1/search?q=%@", escapedSearchText)
    let url = NSURL(string: urlString)!

    let session = NSURLSession.sharedSession()
    dataTask = session.dataTaskWithURL(url, completionHandler: {
      data, response, error in

      if let error = error {
        if error.code == -999 { return }  // request was cancelled

      } else if let httpResponse = response as? NSHTTPURLResponse {
        if httpResponse.statusCode == 200 {
          if let results = self.parseJSON(data) as [JSONDictionary]? {
            self.searchResults = []
            for result in results {
              self.searchResults.append(Item(JSON: result))
            }

            // Sort the results by name.
            // There is no need to save these results to persistent storage
            // because they're only temporary.
            self.searchResults.sort({ item1, item2 in
              item1.itemName.localizedStandardCompare(item2.itemName) == NSComparisonResult.OrderedAscending
            })
          }
        }
      }

      dispatch_async(dispatch_get_main_queue()) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        self.loading = false
        self.tableView.reloadData()
      }
    })

    dataTask?.resume()
  }

  private func parseJSON<T>(data: NSData) -> T? {
    var error: NSError?
    if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) as? T {
      return json
    } else if let error = error {
      println("JSON Error: \(error)")
    } else {
      println("Unknown JSON Error")
    }
    return nil
  }
}
