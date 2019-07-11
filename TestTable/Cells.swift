//
//  Cells.swift
//  TestTable
//
//  Created by Denis Karpenko on 2019-07-11.
//  Copyright © 2019 Denis Karpenko. All rights reserved.
//

import Foundation
import UIKit

// MARK: - HeaderCell

final class HeaderModel: NSObject {
    let title: String
    let buttonURL: String?

    init(title: String, buttonURL: String? = nil) {
        self.title = title
        self.buttonURL = buttonURL
    }
}

final class HeaderCell: UITableViewCell {
    let headerLabel = UILabel()
    static let configurator = CellConfigurator<HeaderCell, HeaderModel>(
        heightForItem: nil,
        configureCell: { cell, item, _ in
            cell.headerLabel.text = item.title
    })
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(headerLabel)
        self.headerLabel.font = .systemFont(ofSize: 50, weight: .bold)
        self.headerLabel.pinToSuperview(excludingEdges: [.right])
    }
    required init?(coder aDecoder: NSCoder) { fatalError("😩") }
}

// MARK: - SpacingCell

final class SpacingCellModel: NSObject {
    let space: CGFloat
    init(space: CGFloat) {
        self.space = space
    }
}
final class SpacingCell: UITableViewCell {
    static let configurator = CellConfigurator<SpacingCell, SpacingCellModel>(
        heightForItem: { item in return item.space },
        configureCell: { cell, item, _ in
            cell.constraintHeight?.constant = item.space
    })
    private static let height: CGFloat = 16
    var constraintHeight: NSLayoutConstraint?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.constraintHeight = self.contentView.pinHeight(SpacingCell.height)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("😩") }
}

// MARK: - Main Cell

final class CreditCardModel: NSObject {
    let bank: String
    let period: String

    init(bank: String, period: String) {
        self.bank = bank
        self.period = period
    }
}

final class InsuranceModel: NSObject {
    let company: String
    let price: String

    init(company: String, price: String) {
        self.company = company
        self.price = price
    }
}

final class MainCell: UITableViewCell {
    static let creditCardConfigurator = CellConfigurator<MainCell, CreditCardModel>(
        heightForItem: nil,
        configureCell: { cell, item, _ in
            cell.mainLabel.text = item.bank
            cell.smallLabel.text = "period: \(item.period)"
    })
    static let insuranceConfigurator = CellConfigurator<MainCell, InsuranceModel>(
        heightForItem: nil,
        configureCell: { cell, item, _ in
            cell.mainLabel.text = item.company
            cell.smallLabel.text = "price: \(item.price)"
    })
    let mainLabel = UILabel()
    let smallLabel = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        mainLabel.font = .systemFont(ofSize: 20, weight: .bold) // hugging
        smallLabel.font = .systemFont(ofSize: 10, weight: .regular)
        let stack = UIStackView(arrangedSubviews: [mainLabel, smallLabel])
        self.addSubview(stack)
        stack.pinToSuperview()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("😩") }
}
