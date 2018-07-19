class VisitorsController < ApplicationController
  layout 'project_layout'
  
  def index
    @user = current_user
    @project = @user.project
  end

  def new
    if current_user && current_user.project.present?
      redirect_to visitors_path
    else
      @project = Project.new
    end
  end

  def create
    @visitor = current_user.build_project(secure_params)
    if @visitor.save
      flash[:notice] = "project created successful"
      redirect_to visitors_path 
    else
      render :new
    end
  end

  private

  def secure_params
    params.require(:project).permit(:project_name,:env,:db_name,:vcpu,:memory,:storage,:exp_date)
  end

end
