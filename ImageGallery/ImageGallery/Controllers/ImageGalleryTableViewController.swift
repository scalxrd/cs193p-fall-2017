//
//  ImageGalleryTableViewController.swift
//  ImageGallery
//
//  Created by 6ai on 14/04/2020.
//  Copyright © 2020 6ai. All rights reserved.
//

import UIKit

class ImageGalleryTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        createNewGalleryIntoDefaultSection()
        let rootIndexPath = IndexPath(row: 0, section: Section.default.rawValue)
        segueToImageGallery(by: rootIndexPath)
    }

    private func segueToImageGallery(by indexPath: IndexPath) {
        let gallery = imageGalleries[indexPath.section][indexPath.row]
        let navigationVC = gallery.navigationVC
        splitViewController?.showDetailViewController(navigationVC, sender: nil)
    }

    private func configureTableView() {
        tableView.register(ImageGalleryTableViewCell.self,
                forCellReuseIdentifier: ImageGalleryTableViewCell.identifier)
        let addBarItem = UIBarButtonItem(barButtonSystemItem: .add,
                target: self, action: #selector(createNewGalleryIntoDefaultSection))
        navigationItem.rightBarButtonItem = addBarItem
    }

    var imageGalleriesNames: [String] {
        get {
            var imageGalleriesExistNames: [String] = []
            Section.allCases.forEach {
                imageGalleriesExistNames += imageGalleries[$0.rawValue].map { $0.name }
            }
            return imageGalleriesExistNames
        }
    }

    @objc private func createNewGalleryIntoDefaultSection() {
        let uniqueGalleryName = "Untitled".madeUnique(withRespectTo: imageGalleriesNames)
        let imageGallery = ImageGallery(name: uniqueGalleryName)
        let indexPath = IndexPath(row: imageGalleries[Section.default.rawValue].count,
                section: Section.default.rawValue)
        imageGalleries[indexPath.section].insert(imageGallery, at: indexPath.row)
        tableView.insertRows(at: [indexPath], with: .middle)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == Section.default.rawValue {
            segueToImageGallery(by: indexPath)
        } else {
            let alertController = UIAlertController(
                    title: "You can't segue to \(imageGalleries[indexPath.section][indexPath.row].name)",
                    message: "Undelete it first", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
        }
    }

    // MARK: - UITableViewDataSource

    enum Section: Int, CustomStringConvertible, CaseIterable {
        case `default`
        case recentlyDeleted

        var description: String {
            switch self {
            case .default: return ""
            case .recentlyDeleted: return "Recently Deleted"
            }
        }
    }

    private var imageGalleries = [[ImageGallery]](repeating: [], count: Section.allCases.count)

    override func numberOfSections(in tableView: UITableView) -> Int {
        imageGalleries.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        imageGalleries[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImageGalleryTableViewCell.identifier,
                for: indexPath) as! ImageGalleryTableViewCell
        cell.delegate = self
        cell.textLabel?.text = imageGalleries[indexPath.section][indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        super.tableView(tableView, titleForHeaderInSection: section)
        if imageGalleries[section].isEmpty {
            return nil
        }
        return Section(rawValue: section)?.description
    }


    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath:
            IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == Section.recentlyDeleted.rawValue else { return nil }
        let action = UIContextualAction(style: .normal, title: "Undelete") { _, _, _ in
            let destinationIndexPath = IndexPath(row: self.imageGalleries[Section.default.rawValue].count,
                    section: Section.default.rawValue)
            self.moveCell(from: indexPath, to: destinationIndexPath)
            tableView.reloadRows(at: [destinationIndexPath], with: .none)

            if self.imageGalleries[Section.recentlyDeleted.rawValue].isEmpty {
                tableView.reloadSections(IndexSet(integer: Section.recentlyDeleted.rawValue), with: .none)
            }
        }
        action.backgroundColor = .blue
        return UISwipeActionsConfiguration(actions: [action])
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        if indexPath.section == Section.default.rawValue {
            // Moving cell to "recently deleted" section.
            let destinationIndexPath = IndexPath(row: imageGalleries[Section.recentlyDeleted.rawValue].count,
                    section: Section.recentlyDeleted.rawValue)
            moveCell(from: indexPath, to: destinationIndexPath)
        } else {
            // Permanently deletes cell from the table.
            imageGalleries[indexPath.section].remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .right)
        }

        // Updating "recently deleted" section when it appears and disappears
        let recentlyDelSec = imageGalleries[Section.recentlyDeleted.rawValue]
        if recentlyDelSec.isEmpty || recentlyDelSec.count == 1 {
            tableView.reloadSections(IndexSet(integer: Section.recentlyDeleted.rawValue), with: .none)
        }
    }

    private func moveCell(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        assert(sourceIndexPath.section < imageGalleries.count)
        assert(sourceIndexPath.row < imageGalleries[sourceIndexPath.section].count)
        assert(destinationIndexPath.section < imageGalleries.count)
        assert(destinationIndexPath.row <= imageGalleries[destinationIndexPath.section].count)

        let movingItem = imageGalleries[sourceIndexPath.section][sourceIndexPath.row]
        imageGalleries[destinationIndexPath.section].insert(movingItem, at: destinationIndexPath.row)
        imageGalleries[sourceIndexPath.section].remove(at: sourceIndexPath.row)
        tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
    }
}

// MARK: - ImageGalleryTableViewCellDelegate

extension ImageGalleryTableViewController: ImageGalleryTableViewCellDelegate {
    func tableViewCellTextContentDidChange(from oldText: String?, to newText: String?) {
        guard let oldText = oldText, let newText = newText,
              let indexPath = getIndexPath(by: oldText) else { return }
        if imageGalleriesNames.contains(newText) {
            let alertController = UIAlertController(title: "'\(newText)' already taken :(",
                    message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
            return
        }
        imageGalleries[indexPath.section][indexPath.row].name = newText
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    private func getIndexPath(by text: String) -> IndexPath? {
        if let row = imageGalleries[Section.default.rawValue].firstIndex(where: { $0.name == text }) {
            return IndexPath(row: row, section: Section.default.rawValue)
        }
        if let row = imageGalleries[Section.recentlyDeleted.rawValue].firstIndex(where: { $0.name == text }) {
            return IndexPath(row: row, section: Section.recentlyDeleted.rawValue)
        }
        return nil
    }
}
