//
//  GoogleTableView.swift
//  TestTable
//
//  Created by Denis Karpenko on 2019-07-11.
//  Copyright © 2019 Denis Karpenko. All rights reserved.
//

import Foundation
import UIKit

@objc class ModelChange: NSObject {
    // add description
    enum Category {
        case insert
        case delete
        case update
        case move
        //        case insertSection
        //        case deleteSection
        //        case moveSection
    }
    private(set) var indexPath: IndexPath?
    private(set) var newIndexPath: IndexPath?
    let category: Category
    init(category: Category, indexPath: IndexPath?, newIndexPath: IndexPath?) {
        self.category = category
        self.indexPath = indexPath
        self.newIndexPath = newIndexPath
    }

    static func deleteItem(_ indexPath: IndexPath) -> ModelChange {
        return ModelChange(category: .delete, indexPath: indexPath, newIndexPath: nil)
    }
    static func insertItem(_ indexPath: IndexPath) -> ModelChange {
        return ModelChange(category: .insert, indexPath: nil, newIndexPath: indexPath)
    }
    static func updateItem(_ indexPath: IndexPath) -> ModelChange {
        return ModelChange(category: .update, indexPath: indexPath, newIndexPath: nil)
    }
    static func moveItem(_ indexPath: IndexPath, to newIndexPath: IndexPath) -> ModelChange {
        return ModelChange(category: .move, indexPath: indexPath, newIndexPath: newIndexPath)
    }
    func set(section: Int) {
        indexPath?.section = section
        newIndexPath?.section = section
    }
}

@objc
protocol SectionModelProtocol {
    func item(at index: Int) -> Any // change to AnyObject
    var numberOfItems: Int { get }
    var didChangeContent: (([ModelChange]) -> Void)? { get set } // new protocol?
}

class MutableSectionModel: SectionModelProtocol {

    var items: [Diffable] {
        didSet {
            self.update(old: oldValue, new: items)
        }
    }
    var numberOfItems: Int { return items.count }
    init(items: [Diffable]) {
        self.items = items
    }

    func item(at index: Int) -> Any { // change to AnyObject
        return items[index]
    }

    var didChangeContent: (([ModelChange]) -> Void)?

    private func update(old: [Diffable], new: [Diffable]) {
        let diff = List.diffing(oldArray: old, newArray: new).forBatchUpdates()
        let deletions = diff.deletes.map { ModelChange.deleteItem(IndexPath(row: $0, section: 0)) }
        let insertions = diff.inserts.map { ModelChange.insertItem(IndexPath(row: $0, section: 0)) }
        let updates = diff.updates.map { ModelChange.updateItem(IndexPath(row: $0, section: 0)) }
        let moves = diff.moves.map { ModelChange.moveItem(IndexPath(row: $0.from, section: 0), to: IndexPath(row: $0.to, section: 0)) }
        let changes = [updates, deletions, insertions, moves].flatMap { $0 }
        self.didChangeContent?(changes)
    }
}

protocol TableModel {
    var sections: [MutableSectionModel] { get }
}

class GoogleTableView: UITableView {
    // : UITableViewController

    var model: TableModel? {
        didSet {
            self.reloadData()
            model!.sections.enumerated().forEach { item in
                item.element.didChangeContent = { [weak self] changes in
                    changes.forEach { $0.set(section: item.offset) }
                    self?.updateTable(with: changes) }
            }
            model!.sections.forEach { section in
                section.didChangeContent = { [weak self] changes in self?.updateTable(with: changes) }
            }
        }
    }

    var configurators: [String: AnyCellConfigurator] = [:]
    var cachedCellHeights: [IndexPath: CGFloat] = [:]
    weak var owner: GoogleTableViewOwner?

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.delegate = self
        self.dataSource = self
    }

    func updateTable(with changes: [ModelChange]) {
        self.performBatchUpdates({
            changes.forEach { change in
                switch change.category {
                case .insert: self.insertRows(at: [change.newIndexPath!], with: .automatic)
                case .delete: self.deleteRows(at: [change.indexPath!], with: .automatic)
                case .update: self.reloadRows(at: [change.indexPath!], with: .automatic)
                case .move: self.moveRow(at: change.indexPath!, to: change.newIndexPath!)
                }
            }
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func register(configurator: AnyCellConfigurator) {
        configurators[configurator.reuseID] = configurator // check if already exists and throw erro
        self.register(configurator.cellClass, forCellReuseIdentifier: configurator.reuseID)
    }

    func objects(for indexPath: IndexPath) -> (item: Any, configurator: AnyCellConfigurator) {
        let item = model!.sections[indexPath.section].item(at: indexPath.row) // FIX
        let thisType: Any.Type = type(of: item)
        let reuseID =  String(describing: thisType)
        let configurator = configurators[reuseID]! // no config, throw an error
        return (item, configurator)
    }
}

extension GoogleTableView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let model = model else { return 0 }
        return model.sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model!.sections[section].numberOfItems // FIX
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (item, configurator) = objects(for: indexPath)
        let cell = dequeueReusableCell(withIdentifier: configurator.reuseID)! // guard as well
        configurator.configureAnyCell(cell, item, indexPath)
        return cell
    }
}

extension GoogleTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // add cachedCellHeights
        let (item, configurator) = objects(for: indexPath)
        if let size = configurator.heightForAnyItem?(item) {
            return size
        } else { // autoHeight Block, better to create dummy cell only once
            let offscreenCell = configurator.instance
            configurator.configureAnyCell(offscreenCell, item, indexPath)
            offscreenCell.updateConstraints()
            offscreenCell.bounds = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: bounds.height))
            offscreenCell.setNeedsLayout()
            offscreenCell.layoutIfNeeded()
            var height = offscreenCell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            if separatorStyle != .none { height += 1 }
            return height
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.owner?.tableView?(self, willDisplayCell: cell, at: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // maybe call automatically
        self.owner?.tableView?(self, didSelectRow: model!.sections[indexPath.section].item(at: indexPath.row), at: indexPath) // FIX
    }
}

struct CellConfigurator<Cell: UITableViewCell, Item: Any> {
    var cellClass: AnyClass { return Cell.self }
    var reuseID: String { return String(describing: Item.self) }
    var heightForItem: ((Item) -> CGFloat)?
    let configureCell: (Cell, Item, IndexPath?) -> ()
    var instance: UITableViewCell { return Cell.init() }
}

extension CellConfigurator: AnyCellConfigurator {
    // do not call directly
    var configureAnyCell: (UITableViewCell, Any, IndexPath?) -> () {
        return { [configureCell] cell, item, indexPath in
            configureCell(cell as! Cell, item as! Item, indexPath)
        }
    }

    var heightForAnyItem: ((Any) -> CGFloat)? {
        return heightForItem.map { height in { item in height(item as! Item) } }
    }
}

protocol AnyCellConfigurator {
    var cellClass: AnyClass { get }
    var reuseID: String { get }
    var heightForAnyItem: ((Any) -> CGFloat)? { get }
    var configureAnyCell: (UITableViewCell, Any, IndexPath?) -> () { get }
    var instance: UITableViewCell { get }
}

@objc
protocol GoogleTableViewOwner: AnyObject {
    @objc optional func tableView(_ tableView: GoogleTableView, didSelectRow model: Any, at indexPath: IndexPath)
    @objc optional func tableView(_ tableView: GoogleTableView, willDisplayCell cell: UITableViewCell, at indexPath: IndexPath)
}

public protocol Diffable {
    func diffEqual(to object: Diffable) -> Bool
    var diffIdentifier: AnyHashable { get }
}
extension NSObject: Diffable {
    public var diffIdentifier: AnyHashable {
        return self
    }

    public func diffEqual(to object: Diffable) -> Bool {
        return isEqual(object)
    }
}

