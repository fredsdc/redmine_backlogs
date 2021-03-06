include RbCommonHelper

class RbTaskboardsController < RbApplicationController
  unloadable

  def show
    stories = @sprint.stories
    @story_ids    = stories.map{|s| s.id}

    @settings = Backlogs.settings

    ## determine status columns to show
    tracker = Tracker.find_by_id(RbTask.tracker)
    statuses = tracker.issue_statuses
    # disable columns by default
    enabled = {}
    statuses.each{|s| enabled[s.id] = false}
    # enable all statuses held by current tasks, regardless of whether the current user has access
    RbTask.where(fixed_version_id: @sprint.id, tracker_id: tracker).find_each {|task| enabled[task.status_id] = true }

    if User.current.admin?
      roles = Role.all
    else
      roles = User.current.roles_for_project(@project)
    end
    #@transitions = {}
    statuses.each {|status|

      # enable all statuses the current user can reach from any task status
      [false, true].each {|creator|
        [false, true].each {|assignee|

          allowed = status.new_statuses_allowed_to(roles, tracker, @project.workspace_id, creator, assignee).collect{|s| s.id}
          #@transitions["c#{creator ? 'y' : 'n'}a#{assignee ? 'y' : 'n'}"] = allowed
          allowed.each{|s| enabled[s] = true}
        }
      }
    }
    @statuses = statuses.select{|s| enabled[s.id]}

    if @sprint.stories.size == 0
      @last_updated = nil
    else
      @last_updated = RbTask.where(tracker_id: RbTask.tracker, fixed_version_id: @sprint.stories[0].fixed_version_id)
                            .order("updated_on DESC").first
    end

    @roles = User.current.admin ? Role.all : User.current.roles_for_project(@project)

    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end

  def current
    sprint = @project.active_sprint
    if sprint
      redirect_to :controller => 'rb_taskboards', :action => 'show', :sprint_id => sprint
      return
    end
    respond_to do |format|
      format.html { redirect_back_or_default(project_url(@project)) }
    end
  end

end
