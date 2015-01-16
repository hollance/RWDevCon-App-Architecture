
import UIKit

class SearchViewController: UITableViewController, UISearchBarDelegate {

  var watchlist: Watchlist!

  var serverAPI: ServerAPI! {
    didSet {
      search.serverAPI = serverAPI
    }
  }

  @IBOutlet weak var searchBar: UISearchBar!

  private var search = Search()

  private lazy var currencyFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencyCode = "USD"
    return formatter
  }()

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
        switch search.state {
        case .Results(let array):
          let controller = segue.destinationViewController as ItemDetailViewController
          controller.item = array[indexPath.row]
          controller.watchlist = watchlist
          controller.serverAPI = serverAPI
        default:
          break
        }
      }
    }
  }

  // MARK: Table View Data Source

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch search.state {
    case .Loading:
      return 1
    case .Error, .NotSearched:
      return 0
    case .Results(let array):
      return array.count
    }
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    switch search.state {
    case .Loading:
      let cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath) as UITableViewCell
      if let spinner = cell.viewWithTag(100) as? UIActivityIndicatorView {
        spinner.startAnimating()
      }
      return cell

    case .Error, .NotSearched:
      fatalError("should not get here")

    case .Results(let array):
      let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell", forIndexPath: indexPath) as ItemCell
      let item = array[indexPath.row]

      cell.itemNameLabel.text = item.itemName

      if item.bids.count == 1 {
        cell.bidderCountLabel.text = "1 Bidder"
      } else {
        cell.bidderCountLabel.text = "\(item.bids.count) Bidders"
      }

      if let highestBid = item.highestBid {
        cell.highestBidLabel.text = currencyFormatter.stringFromNumber(highestBid.amount)
      } else {
        cell.highestBidLabel.text = "-"
      }
      return cell
    }
  }

  // MARK: User Interface Actions

  private func search(searchText: String) {

    search.performSearchForText(searchText) {
      // This will hide the spinner after the search is over, and add the
      // search results to the table view.
      self.tableView.reloadData()
    }

    // This will show the spinner while searching
    tableView.reloadData()
  }
}
