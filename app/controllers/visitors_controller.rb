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
    pvc_availble = PvContainer.where(pv_used: 0).first
    proj_name =  @visitor.try(:project_name)
    if @visitor.save
      p "=============#{proj_name} ===== project"
      p "================ #{TOKEN} =======token======"
      new_project_app(proj_name)
      project_policy_binding(proj_name, current_user.try(:lanid))
      git_url = git_repo_build(proj_name)
      @visitor.git_repo_url = git_url
      @visitor.save
      #test_pvc(proj_name, pvc_availble)
      pvc_build_container(proj_name,pvc_availble)
      #pvc_availble.pv_used = 1
      #pvc_availble.project_name = @visitor.try(:project_name)
      #pvc_availble.save
      mysql_build_container(proj_name,pvc_availble)
      svc_build_container(proj_name)
      flash[:notice] = "project created successful"
      redirect_to visitors_path 
    else
      render :new
    end
  end

  def test_pvc(project_name, pv)
    p "======================#{pv.inspect}  ========= pvvvvv"
    p "=======================#{project_name} ------- project----"
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

  def git_repo_build(project_name)
  
    uri = URI.parse("http://gogs.apps.cpaas.service.test/api/v1/user/repos?token=069a01464480025f134bd21e0f92163a4fe4d63a")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/x-www-form-urlencoded"
    request["Accept"] = "application/json"
    request.set_form_data(
      "name" => project_name+"_repo",
    )

   req_options = {
     use_ssl: uri.scheme == "https",
     verify_mode: OpenSSL::SSL::VERIFY_NONE,
   }

   response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
   end
   data = JSON.parse(response.body)["clone_url"]
   return data
  end

  def pvc_build_container(project_name,pv)
   uri = URI.parse("https://ose.cpaas.service.test:8443/api/v1/namespaces/"+project_name+"/persistentvolumeclaims")
request = Net::HTTP::Post.new(uri)
request.content_type = "application/json"
request["Authorization"] = TOKEN
request["Accept"] = "application/json"
request.body = JSON.dump({
  "kind" => "PersistentVolumeClaim",
  "apiVersion" => "v1",
  "metadata" => {
    "name" => pv.present? ? pv.pv_name+"-pvc" : nil,
    "namespace" => project_name,
    "creationTimestamp" => nil
  },
  "spec" => {
    "accessModes" => [
      "ReadWriteOnce"
    ],
    "resources" => {
      "requests" => {
        "storage" => "50Gi"
      }
    },
    "volumeName" => pv.present? ? pv.pv_name : nil
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

  def mysql_build_container(project_name,pv)
   uri = URI.parse("https://ose.cpaas.service.test:8443/oapi/v1/namespaces/"+project_name+"/deploymentconfigs")
request = Net::HTTP::Post.new(uri)
request.content_type = "application/json"
request["Authorization"] = TOKEN
request["Accept"] = "application/json"
request.body = JSON.dump({
  "apiVersion" => "v1",
  "kind" => "DeploymentConfig",
  "metadata" => {
    "creationTimestamp" => nil,
    "generation" => 1,
    "labels" => {
      "app" => "mysql"
    },
    "name" => "mysql",
    "namespace" => project_name
  },
  "spec" => {
    "replicas" => 1,
    "selector" => {
      "app" => "mysql",
      "deploymentconfig" => "mysql"
    },
    "strategy" => {
      "activeDeadlineSeconds" => 21600,
      "rollingParams" => {
        "intervalSeconds" => 1,
        "maxSurge" => "25%",
        "maxUnavailable" => "25%",
        "timeoutSeconds" => 600,
        "updatePeriodSeconds" => 1
      },
      "type" => "Rolling"
    },
    "template" => {
      "metadata" => {
        "annotations" => {
          "openshift.io/generated-by" => "OpenShiftNewApp"
        },
        "creationTimestamp" => nil,
        "labels" => {
          "app" => "mysql",
          "deploymentconfig" => "mysql"
        }
      },
      "spec" => {
        "containers" => [
          {
            "env" => [
              {
                "name" => "MYSQL_ROOT_PASSWORD",
                "value" => "password"
              }
            ],
            "image" => "dcartifactory.service.dev:5000/openshift3/mysql-57-rhel7:latest",
            "imagePullPolicy" => "Always",
            "name" => "mysql",
            "ports" => [
              {
                "containerPort" => 3306,
                "protocol" => "TCP"
              }
            ],
            "terminationMessagePath" => "/dev/termination-log",
            "terminationMessagePolicy" => "File",
            "volumeMounts" => [
              {
                "mountPath" => "/var/lib/mysql/data",
                "name" => "mysql-data"
              }
            ]
          }
        ],
        "dnsPolicy" => "ClusterFirst",
        "restartPolicy" => "Always",
        "schedulerName" => "default-scheduler",
        "terminationGracePeriodSeconds" => 30,
        "volumes" => [
          {
            "name" => "mysql-data"
          }
        ]
      }
    },
    "test" => false
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

  def svc_build_container(project_name)
   uri = URI.parse("https://ose.cpaas.service.test:8443/api/v1/namespaces/"+project_name+"/services")
request = Net::HTTP::Post.new(uri)
request.content_type = "application/json"
request["Authorization"] = TOKEN
request["Accept"] = "application/json"
request.body = JSON.dump({
  "apiVersion" => "v1",
  "kind" => "Service",
  "metadata" => {
    "creationTimestamp" => nil,
    "name" => "mysql",
    "namespace" => project_name
  },
  "spec" => {
    "ports" => [
      {
        "name" => "3306-tcp",
        "port" => 3306,
        "protocol" => "TCP",
        "targetPort" => 3306
      }
    ],
    "sessionAffinity" => "None",
    "type" => "ClusterIP"
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

  def destroy
    project = Project.find_by_id(params[:id])
    uri = URI.parse("https://ose.cpaas.service.test:8443/oapi/v1/projects/"+project.try(:project_name))
request = Net::HTTP::Delete.new(uri)
request.content_type = "application/json"
request["Authorization"] = TOKEN
request["Accept"] = "application/json"
request.body = JSON.dump({
  "orphanDependents" => false
})

req_options = {
  use_ssl: uri.scheme == "https",
  verify_mode: OpenSSL::SSL::VERIFY_NONE,
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end
  project.destroy
  #pv_update = PvContainer.where(project_name: project.project_name).first
  #pv_update.pv_used = 0
  #pv_update.save
  redirect_to new_visitor_path
  end

  private

  def secure_params
    params.require(:project).permit(:project_name,:env,:db_name,:vcpu,:memory,:storage,:exp_date)
  end

end
