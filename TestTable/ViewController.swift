//
//  ViewController.swift
//  TestTable
//
//  Created by Denis Karpenko on 2019-07-11.
//  Copyright © 2019 Denis Karpenko. All rights reserved.
//

import UIKit

final class StoreModel: TableModel {
    let sections: [MutableSectionModel]
    init(items: [Diffable]) {
        self.sections = [MutableSectionModel(items: items)]
    }
    func addCreditCardToRandomPlace() {
        let randomBank =  CreditCardModel(bank: "\(randomString(length: 5)) Bank", period: "\(Int.random(in: 5..<100)) years")
        sections[0].items.insert(randomBank, at: Int.random(in: 0...sections[0].items.count))

    }
    func deleteLast() {
        guard !sections[0].items.isEmpty else { return }
        sections[0].items.remove(at: Int.random(in: 0..<sections[0].items.count))
    }
    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

class ViewController: UIViewController {

    var controllerModel: StoreModel!
    let table = GoogleTableView()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.controllerModel = StoreModel(items: [HeaderModel(title: "Hello"),
                                                SpacingCellModel(space: 8),
                                                HeaderModel(title: "Cards"),
                                                SpacingCellModel(space: 4),
                                                CreditCardModel(bank: "Bank of America", period: "3 years"),
                                                CreditCardModel(bank: "CitiBank", period: "1 year"),
                                                HeaderModel(title: "Insurances"),
                                                SpacingCellModel(space: 4),
                                                InsuranceModel(company: "BestInsurance", price: "100 dollars"),
                                                InsuranceModel(company: "NormalInsurance", price: "50 dollars"),
                                                InsuranceModel(company: "BadInsurance", price: "10 dollars"),
                                                SpacingCellModel(space: 16),
                                                HeaderModel(title: "The End"),
            ])

        self.setupTable()
        self.addButtons()
    }

    private func regirstConfigurators() {
        table.register(configurator: HeaderCell.configurator)
        table.register(configurator: SpacingCell.configurator)
        table.register(configurator: MainCell.creditCardConfigurator)
        table.register(configurator: MainCell.insuranceConfigurator)
    }

    private func addButtons() {
        let addButton = UIButton()
        addButton.setTitle("+", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 60, weight: .bold)
        addButton.setBackgroundImage(UIColor.green.getImage(), for: .normal)
        addButton.addAction(for: .touchUpInside) { [weak self] in
            self?.controllerModel.addCreditCardToRandomPlace()
        }
        let minusButton = UIButton()
        minusButton.addAction(for: .touchUpInside) { [weak self] in
            self?.controllerModel.deleteLast()
        }
        minusButton.titleLabel?.font = .systemFont(ofSize: 60, weight: .bold)
        minusButton.setTitle("-", for: .normal)
        minusButton.setBackgroundImage(UIColor.red.getImage(), for: .normal)
        let stack = UIStackView(arrangedSubviews: [addButton, minusButton])
        stack.spacing = 16
        self.view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -32).isActive = true
        stack.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    }

    private func setupTable() {
        self.view.addSubview(table)
        table.pinToSuperview()
        table.separatorStyle = .none
        self.regirstConfigurators()
        self.table.model = controllerModel
    }
}

