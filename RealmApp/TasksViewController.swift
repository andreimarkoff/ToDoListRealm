//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Andrey Markov on 2020-12-04.
//

import UIKit
import RealmSwift
class TasksViewController: UITableViewController {
    
    var taskList: TaskList!
    
    var currentTasks: Results<Task>!
    var completedTasks: Results<Task>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.name
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURREENT TASKS" : "COMPLETED TASKS"
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        cell.textLabel?.text = task.name
        cell.detailTextLabel?.text = task.note
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, _) in
            StorageManager.shared.delete(task: task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        let editAction = UIContextualAction(style: .normal, title: "Edit") { (_, _, isDone) in
            self.showAlert(with: task) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        let doneAction = UIContextualAction(style: .normal, title: "Done") { (_, _, isDone) in
            
            StorageManager.shared.done(task: task)
            
            let indexPathForCurrentTask = IndexPath(row: self.currentTasks.count - 1, section: 0)
            let indexPathForCompletedTask = IndexPath(row: self.completedTasks.count - 1, section: 1)
            let destinationIndexPath = indexPath.section == 0 ? indexPathForCompletedTask : indexPathForCurrentTask
            
            tableView.moveRow(at: indexPath, to: destinationIndexPath)
            
            isDone(true)
        }
        editAction.backgroundColor = #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)
        doneAction.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    @objc private func addButtonPressed(){
        showAlert()
    }
}
extension TasksViewController{
    private func showAlert(with task: Task? = nil, completion: (() -> Void)? = nil){
        
        let title = task != nil ? "Edit Task" : "New Task"
        
        let alert = AlertController(title: title, message: "What do you want to do", preferredStyle: .alert)
        alert.action(with: task){ newValue, note in
            if let task = task, let completion = completion{
                StorageManager.shared.edit(task: task, name: newValue, note: note)
                completion()
            }else{
                let task = Task(value: [newValue, note])
                StorageManager.shared.save(task: task, in: self.taskList)
                let rowIndex = IndexPath(row: self.currentTasks.count - 1, section: 0)
                self.tableView.insertRows(at: [rowIndex], with: .automatic)
            }
        }
        
        present(alert, animated: true)
    }
}
