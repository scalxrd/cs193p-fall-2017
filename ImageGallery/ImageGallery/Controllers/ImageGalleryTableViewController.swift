////  ImageGalleryTableViewController.swift//  ImageGallery////  Created by 6ai on 14/04/2020.//  Copyright © 2020 6ai. All rights reserved.//import UIKitclass ImageGalleryTableViewController: UITableViewController {    override func viewDidLoad() {        super.viewDidLoad()        configureTableView()        createImageGallery()        segueToImageGallery(with: 0)    }    private func segueToImageGallery(with index: Int) {        splitViewController?.showDetailViewController(imageGalleries[0][index].navigationVC, sender: nil)    }    private func configureTableView() {        tableView.register(ImageGalleryTableViewCell.self, forCellReuseIdentifier: ImageGalleryTableViewCell.identifier)        let addBarItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createImageGallery))        navigationItem.rightBarButtonItem = addBarItem    }    @objc private func createImageGallery() {        let imageGalleriesExistNames = imageGalleries[1].map { $0.name } + imageGalleries[0].map { $0.name }        let uniqueGalleryName = "Untitled".madeUnique(withRespectTo: imageGalleriesExistNames)        let imageGallery = ImageGallery(name: uniqueGalleryName)        imageGalleries[0].append(imageGallery)        tableView.reloadData()    }    // MARK: - UITableViewDelegate    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {        tableView.deselectRow(at: indexPath, animated: true)        if indexPath.section == 0 {            segueToImageGallery(with: indexPath.row)        }    }    // MARK: - UITableViewDataSource    private var imageGalleries: [[ImageGallery]] = [[], []]    override func numberOfSections(in tableView: UITableView) -> Int {        imageGalleries.count    }    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {        imageGalleries[section].count    }    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        let cell = tableView.dequeueReusableCell(withIdentifier: ImageGalleryTableViewCell.identifier,                for: indexPath) as! ImageGalleryTableViewCell        cell.delegate = self        cell.textLabel?.text = imageGalleries[indexPath.section][indexPath.row].name        return cell    }    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {        print(#function)        super.tableView(tableView, titleForHeaderInSection: section)        if section == 1, imageGalleries[1].count > 0 {            return "Recently Deleted"        }        return nil    }//    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath:            IndexPath) -> UISwipeActionsConfiguration? {        guard indexPath.section == 1 else { return nil }        let action = UIContextualAction(style: .normal, title: "Undelete", handler: { _, _, _ in            let item = self.imageGalleries[indexPath.section][indexPath.row]            self.imageGalleries[0].append(item)            self.imageGalleries[1].remove(at: indexPath.row)            let destinationIndexPath = IndexPath(row: self.imageGalleries[0].count - 1, section: 0)            tableView.moveRow(at: indexPath, to: destinationIndexPath)            if self.imageGalleries[1].count == 0 {                tableView.reloadSections(IndexSet(integer: 1), with: .none)            }        })        action.backgroundColor = .green        return UISwipeActionsConfiguration(actions: [action])    }    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,                            forRowAt indexPath: IndexPath) {        if editingStyle == .delete {            if indexPath.section == 0 {                // Moving cell to "recently deleted" section                let item = imageGalleries[0][indexPath.row]                imageGalleries[indexPath.section + 1].append(item)                imageGalleries[indexPath.section].remove(at: indexPath.row)                let destinationIndexPath = IndexPath(row: imageGalleries[indexPath.section + 1].count - 1, section: 1)                tableView.moveRow(at: indexPath, to: destinationIndexPath)            } else {                // Permanently deletes cell from the table.                imageGalleries[indexPath.section].remove(at: indexPath.row)                tableView.deleteRows(at: [indexPath], with: .right)            }            // Updating "recently deleted" section when it appears and disappears            let recentlyDelSec = imageGalleries[1]            if (recentlyDelSec.count == 0) || (recentlyDelSec.count == 1) {                tableView.reloadSections(IndexSet(integer: 1), with: .none)            }        }    }}// MARK: - ImageGalleryTableViewCellDelegateextension ImageGalleryTableViewController: ImageGalleryTableViewCellDelegate {    func tableViewCellTextContentDidChange(from oldText: String?, to newText: String?) {        guard let oldText = oldText, let newText = newText,              let indexPath = getIndexPath(by: oldText) else { return }        imageGalleries[indexPath.section][indexPath.row].name = newText        tableView.reloadRows(at: [indexPath], with: .top)    }    private func getIndexPath(by cellText: String) -> IndexPath? {        if let index = imageGalleries[0].firstIndex(where: { $0.name == cellText }) {            return IndexPath(row: index, section: 0)        }        if let index = imageGalleries[1].firstIndex(where: { $0.name == cellText }) {            return IndexPath(row: index, section: 1)        }        return nil    }}