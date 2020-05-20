////  ImageGalleryTableViewController.swift//  ImageGallery////  Created by 6ai on 14/04/2020.//  Copyright © 2020 6ai. All rights reserved.//import UIKitclass ImageGalleryTableViewController: UITableViewController {    override func viewDidLoad() {        super.viewDidLoad()        configureTableView()        createImageGallery()        segueToImageGallery(with: 0)    }    private func segueToImageGallery(with index: Int) {        splitViewController?.showDetailViewController(imageGalleries[0][index].navigationVC, sender: nil)    }    private func configureTableView() {        tableView.register(ImageGalleryTableViewCell.self, forCellReuseIdentifier: ImageGalleryTableViewCell.identifier)        let addBarItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createImageGallery))        navigationItem.rightBarButtonItem = addBarItem    }    @objc private func createImageGallery() {        let imageGalleriesExistNames = imageGalleries[1].map { $0.name } + imageGalleries[0].map { $0.name }        let uniqueGalleryName = "Untitled".madeUnique(withRespectTo: imageGalleriesExistNames)        let imageGallery = ImageGallery(name: uniqueGalleryName)        imageGalleries[0].append(imageGallery)        tableView.reloadData()    }    // MARK: - UITableViewDelegate    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {        tableView.deselectRow(at: indexPath, animated: true)        if indexPath.section == 0 {            segueToImageGallery(with: indexPath.row)        }    }    // MARK: - UITableViewDataSource    private var imageGalleries: [[ImageGallery]] = [[], []]    override func numberOfSections(in tableView: UITableView) -> Int {        return imageGalleries.count    }    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {        return imageGalleries[section].count    }    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        let cell = tableView.dequeueReusableCell(withIdentifier: ImageGalleryTableViewCell.identifier,                for: indexPath) as! ImageGalleryTableViewCell        cell.delegate = self        cell.textLabel?.text = imageGalleries[indexPath.section][indexPath.row].name        return cell    }    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {        print(#function)        super.tableView(tableView, titleForHeaderInSection: section)        switch section {        case 0: return nil        case 1: return imageGalleries[1].count > 0 ? "Recently Deleted" : ""        default: return ""        }    }//    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath:            IndexPath) -> UISwipeActionsConfiguration? {        guard indexPath.section == 1 else { return nil }        let action = UIContextualAction(style: .normal, title: "Undelete", handler: { _, _, _ in            let item = self.imageGalleries[indexPath.section][indexPath.row]            self.imageGalleries[0].append(item)            self.imageGalleries[1].remove(at: indexPath.row)            let destinationIndexPath = IndexPath(row: self.imageGalleries[0].count - 1, section: 0)            tableView.moveRow(at: indexPath, to: destinationIndexPath)        })        action.backgroundColor = .green        return UISwipeActionsConfiguration(actions: [action])    }    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,                            forRowAt indexPath: IndexPath) {        print(#function)        if editingStyle == .delete {            if indexPath.section == 0 {                let item = imageGalleries[0][indexPath.row]                imageGalleries[indexPath.section + 1].append(item)                imageGalleries[indexPath.section].remove(at: indexPath.row)                let destinationIndexPath = IndexPath(row: imageGalleries[indexPath.section + 1].count - 1, section: 1)                tableView.moveRow(at: indexPath, to: destinationIndexPath)            } else {                imageGalleries[indexPath.section].remove(at: indexPath.row)                tableView.deleteRows(at: [indexPath], with: .right)            }        }    }}extension ImageGalleryTableViewController: ImageGalleryTableViewCellDelegate {    func tableViewCellTextContentDidChange(from oldText: String?, to newText: String?) {        guard let oldText = oldText, let newText = newText else { return }        var indexPath = IndexPath()        if let index = imageGalleries[0].firstIndex(where: { $0.name == oldText }) {            indexPath.row = index            indexPath.section = 0        } else if let index = imageGalleries[1].firstIndex(where: { $0.name == oldText }) {            indexPath.row = index            indexPath.section = 1        }        print(indexPath)        imageGalleries[indexPath.section][indexPath.row].name = newText        tableView.reloadRows(at: [indexPath], with: .top)    }}