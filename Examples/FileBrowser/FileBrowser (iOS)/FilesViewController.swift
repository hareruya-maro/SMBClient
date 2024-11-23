import UIKit
import AVKit
import SMBClient

class FilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let treeAccessor: TreeAccessor
  private let path: String
  private var files = [File]()

  private let tableView = UITableView(frame: .zero, style: .plain)

  private var dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .none
    return dateFormatter
  }()

  init(accessor: TreeAccessor, path: String) {
    treeAccessor = accessor
    self.path = path
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if !path.isEmpty {
      navigationItem.title = URL(fileURLWithPath: path).lastPathComponent
    }

    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: tableView.topAnchor),
      view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
    ])

    Task { @MainActor in
      do {
        let files = try await treeAccessor.listDirectory(path: path)
          .filter { $0.name != "." && $0.name != ".." && !$0.isHidden }
          .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        self.files.append(contentsOf: files)
        tableView.reloadData()
      } catch let error as LocalizedError {
        let controller = UIAlertController(title: error.errorDescription, message: error.failureReason, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .default))
        present(controller, animated: true)
      } catch {
        let controller = UIAlertController(title: "", message: error.localizedDescription, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .default))
        present(controller, animated: true)
      }
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: indexPathForSelectedRow, animated: animated)
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    tableView.flashScrollIndicators()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    files.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

    let file = files[indexPath.row]

    var configuration = UIListContentConfiguration.subtitleCell()
    configuration.textProperties.numberOfLines = 1
    let fontSize =  configuration.secondaryTextProperties.font.pointSize
    configuration.secondaryTextProperties.font = UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular)

    if file .isDirectory {
      configuration.image = UIImage(systemName: "folder")
      configuration.text = file.name
      configuration.secondaryText = dateFormatter.string(from: file.lastWriteTime)

      cell.accessoryType = .disclosureIndicator
    } else {
      configuration.image = UIImage(systemName: "doc")
      configuration.text = file.name

      let date = dateFormatter.string(from: file.lastWriteTime)
      let size = ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file)
      configuration.secondaryText = "\(date) - \(size)"

      cell.accessoryType = .none
    }

    cell.contentConfiguration = configuration

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let file = files[indexPath.row]
    
    Task { @MainActor in
      let subpath: String
      if path.isEmpty {
        subpath = file.name
      } else {
        subpath = "\(path)/\(file.name)"
      }

      if file.isDirectory {
        let viewController = FilesViewController(accessor: treeAccessor, path: subpath)
        navigationController?.pushViewController(viewController, animated: true)
      } else {
        let path = URL(fileURLWithPath: subpath)
        if MediaPlayerViewController.supportedExtensions.contains(path.pathExtension) {
          let viewController = MediaPlayerViewController(accessor: treeAccessor, path: subpath)
          navigationController?.pushViewController(viewController, animated: true)
        } else {
          let viewController = DocumentViewController(accessor: treeAccessor, path: subpath)
          navigationController?.pushViewController(viewController, animated: true)
        }
      }
    }
  }
}
