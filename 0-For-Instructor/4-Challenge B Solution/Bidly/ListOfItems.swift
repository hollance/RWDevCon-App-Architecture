
import Foundation

class ListOfItems {
  private var items: [Item]

  convenience init() {
    self.init(items: [])
  }

  init(items: [Item]) {
    self.items = items.sorted({ item1, item2 in
      item1.itemName.localizedStandardCompare(item2.itemName) == NSComparisonResult.OrderedAscending
    })
  }

  subscript(index: Int) -> Item {
    return items[index]
  }

  var count: Int {
    return items.count
  }

  func indexOfItem(item: Item) -> Int? {
    return find(items, item)
  }
}
