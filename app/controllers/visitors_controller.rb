class VisitorsController < ApplicationController
  layout 'project_layout'
   require 'net/http'
   require 'uri'
   require 'json'
   require 'openssl'
  TOKEN = "Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJvcGVuc2hpZnQtaW5mcmEiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoicG9jZmx5LXRva2VuLXZ2ZjhuIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6InBvY2ZseSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImNlM2ZmNWVhLThiMjktMTFlOC04ZmVhLTAwMWRkOGI3MjU4MSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpvcGVuc2hpZnQtaW5mcmE6cG9jZmx5In0.YE7JCkuKZiERZpPGoI6cpDRXtymrRvy_NU4SqujEsx5QdO2CobUOBo37o4hFvn6UNtU_95iIRzPUMOfLIsPNh7R_3DbKxP3Z5XNB648987_fbb2dbjAGPgc_R98z4NixgDHsp0UZgDx3cqfwDFQVBCBzFRflpMFdA69Vv-p6-RNHq0rMwl_ddZL-4qcL8NaxeTnUfNQfROUTOUqtF6vYyhfUQzsAlNrqUZinXpLlaTdj4EKbpbGWlecA0jrG2j26eMrOLQlsKsNfm6Sm57eGTNidDlxDUGYD6hgyjQW9uKLUtCZ3snaa4CYUTyjSs1I5lijZAKm-n2pxlnl97r2K3g"
    
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
    p "===================#{@visitor.inspect}================="
    if @visitor.save
      p "===============#{@visitor.project_name} ===== project"
      p "================ #{TOKEN} =======token======"
      new_project_app(@visitor.try(:project_name))
      project_policy_binding(@visitor.try(:project_name), current_user.try(:lanid))
      flash[:notice] = "project created successful"
      redirect_to visitors_path 
    else
      render :new
    end
  end

  def new_project_app(project_name)
    uri = URI.parse("https://ose.cpaas.service.test:8443/oapi/v1/projectrequests")
request = Net::HTTP::Post.new(uri)
request.content_type = "application/json"
request["Accept"] = "application/json"
request["Authorization"] = TOKEN
request.body = JSON.dump({
  "kind" => "ProjectRequest",
  "apiVersion" => "v1",
  "metadata" => {
    "name" => project_name,
    "creationTimestamp" => nil
  }
})

req_options = {
  use_ssl: uri.scheme == "https",
  verify_mode: OpenSSL::SSL::VERIFY_NONE,
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end
  end

  def project_policy_binding(project_name,lanid)
    uri = URI.parse("https://ose.cpaas.service.test:8443/oapi/v1/namespaces/"+project_name+"/rolebindings/admin")
    request = Net::HTTP::Put.new(uri)
    request.content_type = "application/json"
    request["Accept"] = "application/json"
    request["Authorization"] = TOKEN
    request.body = JSON.dump({
  "kind" => "RoleBinding",
  "apiVersion" => "v1",
  "metadata" => {
    "name" => "admin",
    "namespace" => project_name
  },
  "userNames" => [
    "system:serviceaccount:openshift-infra:pocfly",
    lanid
  ],
  "groupNames" => nil,
  "subjects" => [
    {
      "kind" => "ServiceAccount",
      "namespace" => "openshift-infra",
      "name" => "pocfly"
    },
    {
      "kind" => "User",
      "name" => lanid
    }
  ],
  "roleRef" => {
    "name" => "admin"
  }
})

   req_options = {
     use_ssl: uri.scheme == "https",
     verify_mode: OpenSSL::SSL::VERIFY_NONE,
   }

   response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
     http.request(request)
   end

  end

  private

  def secure_params
    params.require(:project).permit(:project_name,:env,:db_name,:vcpu,:memory,:storage,:exp_date)
  end

end
