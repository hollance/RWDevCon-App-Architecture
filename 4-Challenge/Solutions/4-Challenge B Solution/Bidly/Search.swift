
import Foundation

/*
  Represents a search, either one that is in progress or one that has finished
  with results.
 */
class Search {
  var serverAPI: ServerAPI!

  enum State {
    case NotSearched
    case Loading
    case Error
    case Results([Item])
  }

  private(set) var state = State.NotSearched
  private var request: SearchRequest?

  init() {
    // Swift complains if we don't have this
  }

  func performSearchForText(searchText: String, completionHandler: () -> Void) {
    request?.cancel()

    state = .Loading

    request = SearchRequest(searchText: searchText) { results in
      if let results = results as? [JSONDictionary] {
        var searchResults = [Item]()

        for json in results {
          searchResults.append(Item(JSON: json))
        }

        // Sort the results by name.
        // There is no need to save these results to persistent storage
        // because they're only temporary.
        searchResults.sort({ item1, item2 in
          item1.itemName.localizedStandardCompare(item2.itemName) == NSComparisonResult.OrderedAscending
        })

        self.state = .Results(searchResults)
      } else {
        self.state = .Error
      }

      completionHandler()
    }

    serverAPI.sendRequest(request!)
  }
}
