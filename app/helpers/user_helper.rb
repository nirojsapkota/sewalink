module UserHelper
  def mask_contact_info(text, visible: false)
    visible ? text : "[HIDDEN UNTIL ASSIGNED]"
  end

  def can_see_contact_info?(target_user, task: nil)
    return true if current_user == target_user
    return false unless task
    
    task.assigned? && (current_user == task.user || current_user == task.tasker) && (target_user == task.user || target_user == task.tasker)
  end
end
