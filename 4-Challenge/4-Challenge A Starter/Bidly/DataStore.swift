
import Foundation

class DataStore {
  // Use this to access the Watchlist object. This first time you access it,
  // the data store will load the watchlist from disk into memory.
  lazy var watchlist: Watchlist = {
    if let items = self.loadWatchlist() {
      return Watchlist(items: items)
    } else {
      return Watchlist(items: [])
    }
  }()

  private func dataFilePath() -> String {
    return applicationDocumentsDirectory().stringByAppendingPathComponent("Watchlist.plist")
  }

  private func loadWatchlist() -> [Item]? {
    let path = dataFilePath()
    if NSFileManager.defaultManager().fileExistsAtPath(path) {
      if let data = NSData(contentsOfFile: path) {
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        let items = unarchiver.decodeObjectForKey("Items") as [Item]
        unarchiver.finishDecoding()
        return items
      }
    }
    return nil
  }

  func saveWatchlist() {
    println("Saving file to: '\(dataFilePath())'")
    let data = NSMutableData()
    let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
    archiver.encodeObject(watchlist.items, forKey: "Items")
    archiver.finishEncoding()
    if !data.writeToFile(dataFilePath(), atomically: true) {
      println("Error saving file to: '\(dataFilePath())'")
    }
  }
}
