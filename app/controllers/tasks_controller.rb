class TasksController < ApplicationController
  #auto_complete_for :user, :nick
  
  def index
    @non_group_tasks = Task.find :all, :conditions => "group_id IS NULL AND done = 0", :order => "due_date ASC"
    @groups = Group.find :all, :conditions => "type != 'OrderGroup'"
  end
  
  def myTasks
    @unaccepted_tasks = @current_user.unaccepted_tasks
    @accepted_tasks = @current_user.accepted_tasks
  end
  
  def new
    if params[:id]
      group = Group.find(params[:id])
      @task = group.tasks.build :name => group.task_name,
                                :required_users => group.task_required_users,
                                :description => group.task_description,
                                :due_date => group.next_weekly_tasks[params[:task_from_now].to_i]
    else
      @task = Task.new
    end
  end
  
  def create
    @task = Task.new(params[:task])
    if @task.errors.empty?
      @task.save
      flash[:notice] = "Aufgabe wurde erstellt"
      if @task.group
        redirect_to :action => "workgroup", :id => @task.group
      else
        redirect_to :action => "index"
      end          
    else
      render :template => "tasks/new"
    end
  end
  
  def show
    @task = Task.find(params[:id])
  end
  
  def edit
    @task = Task.find(params[:id])
  end
  
  def update
    @task = Task.find(params[:id])
    @task.attributes=(params[:task])
    if @task.errors.empty?
      @task.save
      flash[:notice] = "Aufgabe wurde aktualisiert"
      if @task.group
        redirect_to :action => "workgroup", :id => @task.group
      else
        redirect_to :action => "index"
      end
    else
      render :template => "tasks/edit"
    end
  end
  
  def destroy
    Task.find(params[:id]).destroy
    redirect_to :action => "index"
  end
  
  # Delete an given Assignment
  # currently used in edit-view
  def drop_assignment
    ass = Assignment.find(params[:id])
    task = ass.task
    ass.destroy
    redirect_to :action => "show", :id => task
  end
  
  # assign current_user to the task and set the assignment to "accepted"
  # if there is already an assignment, only accepted will be set to true
  def accept
    task = Task.find(params[:id])
    if ass = task.is_assigned?(current_user)
      ass.update_attribute(:accepted, true)
    else
      task.assignments.create(:user => current_user, :accepted => true)
    end
    flash[:notice] = "Du hast die Aufgabe übernommen"
    redirect_to :action => "myTasks"
  end
  
  # deletes assignment between current_user and given task
  def reject
    Task.find(params[:id]).users.delete(current_user)
    redirect_to :action => "index"
  end
  
  def update_status
    Task.find(params[:id]).update_attribute("done", params[:task][:done])
    flash[:notice] = "Aufgabenstatus wurde aktualisiert"
    redirect_to :action => "index"
  end
  
  # Shows all tasks, which are already done
  def archive
    @tasks = Task.find :all, :conditions => "done = 1", :order => "due_date DESC"
  end
  
  # shows workgroup (normal group) to edit weekly_tasks_template
  def workgroup
    @group = Group.find(params[:id])
    if @group.is_a? OrderGroup
      flash[:error] = "Keine Arbeitsgruppe gefunden"
      redirect_to :action => "index"
    end
  end
  
  # this method is uses for the auto_complete-function from script.aculo.us
  def auto_complete_for_task_user_list
    @users = User.find(
      :all,
      :conditions => [ 'LOWER(nick) LIKE ?', '%' + params[:task][:user_list].downcase + '%' ], 
      :order => 'nick ASC',
      :limit => 8
    )
    render :partial => '/shared/auto_complete_users'
  end
end
