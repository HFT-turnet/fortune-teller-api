class V1::CsController < ApplicationController
  #controller=V1::SchemeController.new
  #controller.income
  
  def test
    puts "Hall"
  end
  
  def listschemes
    if params[:countrycode].blank? then
      render json: "Please submit parameter 'countrycode'."
    else
      render json: Calcscheme.new.listall(params["countrycode"])
    end
  end
  
  def listmeta
    if params[:countrycode].blank? then
      render json: "Please submit parameter 'countrycode'."
    else
      render json: Calcscheme.new.meta_listall(params["countrycode"])
    end
  end
  
  def get_schemetype
    check=check_schemetype(params[:countrycode], params[:schemetype])
    if check=="OK"
      # Do the work
      definition=Calcscheme.new
      definition.load(params[:countrycode],params[:schemetype])
      render json: {:country => definition.country,
                    :title => definition.title,
                    :comment1 => definition.comment1, 
                    :input => definition.input,
                    :versions => definition.schemes_versions}
    else
      render json: check
    end
  end
  
  def run_scheme
    # Expects params. These include the scheme, the calculation and version.
    # Also include post-payload for the required calculation
    
    # if param[:debug] is set, then instead of result the debuglog is parsed back.
    
    # Check all required file-level params are there
    check1=check_schemetype(params[:countrycode], params[:schemetype])
    unless check1=="OK"
      jsoncheck='{"error": "'+check1+'"}'
      render json: jsoncheck
      return
    end
    
    # Initialize the definition
    definition=Calcscheme.new
    definition.load(params[:countrycode], params[:schemetype])
    # Check all required scheme-level params are there
    check2=check_scheme(definition, params[:scheme], params[:version])
    #puts definition
    unless check2=="OK"
      if check2.first(10)=="Corrected:"
        jsonnotice='{"notice": "'+check2+'"}'
      else
        jsoncheck='{"error": "'+check2+'"}'
        render json: jsoncheck
        return
      end
    end
    
    # Convert parameters to input
    inputs={}
    if params[:c].blank?
      #render json: "Input parameters must be provided as json payload." 
      jsoncheck='{"error": "Input parameters must be provided as json payload."}'
      render json: jsoncheck
      return
    end
    params[:c].each { |key,value| inputs[key]=value }
    
    # Run Scheme, this automatically checks whether necessary inputs have been provided.
    check3=definition.run(inputs, params[:debug])
    unless check3=="OK"
      jsoncheck='{"error": "'+check3+'"}'
      render json: jsoncheck
      return 
    end
    
    jsonnotice='{"notice": ""}' if jsonnotice.blank?
    # Feedback results, disclaimer and any error messages along the way
    render json: definition.result.to_json + jsonnotice.to_json unless params[:debug]=="x"
    
    # Output Debugging information if debug is requested.
    render json: {
              :result => definition.result,
              :debuglog => definition.debuglog
              } if params[:debug]=="x"
  end
  
  def get_metaschemetype
    check=check_metaschemetype(params[:countrycode], params[:metaschemetype])
    if check=="OK"
      definition=Calcscheme.new
      definition.meta_load(params[:countrycode],params[:metaschemetype])
      render json: {:country => definition.country,
                    :title => definition.title,
                    :comment1 => definition.comment1, 
                    :input => "You need to call /{metascheme}/{version} with GET to obtain Inputs",
                    :versions => definition.schemes_versions}
    else
      render json: check
    end
  end
  
  def get_metascheme
    # Check all required file-level params are there
    check1=check_metaschemetype(params[:countrycode], params[:metaschemetype])
    unless check1=="OK"
      render json: check1
      return
    end
    
    # Initialize the definition
    definition=Calcscheme.new
    definition.meta_load(params[:countrycode], params[:metaschemetype])
    # Check all required scheme-level params are there
    check2=check_scheme(definition, params[:metascheme], params[:version])
    #puts definition
    unless check2=="OK"
      render json: check2
      return # or should we continue
    end
    render json: {:country => definition.country,
                  :title => definition.title,
                  :comment1 => definition.comment1, 
                  :selected => definition.setscheme_version,
                  :input => definition.meta_inputs
                  }
  end
  
  def run_metascheme
    # Expects params. These include the scheme, the calculation and version.
    # Also include post-payload for the required calculation
        
    # Check all required file-level params are there
    check1=check_metaschemetype(params[:countrycode], params[:metaschemetype])
    unless check1=="OK"
      jsoncheck='{"error": "'+check1+'"}'
      render json: jsoncheck
      return
    end
    
    # Initialize the definition
    definition=Calcscheme.new
    definition.meta_load(params[:countrycode], params[:metaschemetype])
    # Check all required scheme-level params are there
    check2=check_scheme(definition, params[:metascheme], params[:version])
    #puts definition
    unless check2=="OK"
      if check2.first(10)=="Corrected:"
        jsonnotice='{"notice": "'+check2+'"}'
      else
        jsoncheck='{"error": "'+check2+'"}'
        render json: jsoncheck
        return # or should we continue
      end
    end
    
    # Convert parameters to input
    inputs={}
    if params[:c].blank?
      jsoncheck='{"error": "Input parameters must be provided as json payload."}'
      render json: jsoncheck
      return
    end
    params[:c].each { |key,value| inputs[key]=value }
    
    # Run Scheme, this automatically checks whether necessary inputs have been provided.
    check3=definition.meta_run(inputs)
    unless check3=="OK"
      jsoncheck='{"error": "'+check3+'"}'
      render json: jsoncheck
      return 
    end
    
    jsonnotice='{"notice": ""}' if jsonnotice.blank?
    # Feedback results, disclaimer and any error messages along the way
    render json: definition.result.to_json + jsonnotice.to_json

    # Feedback results, disclaimer and any error messages along the way
    #render json: definition.result
  end
  
  private
  def check_schemetype(countrycode, type)
    if countrycode.blank? then
      return "Please submit parameter 'countrycode'."
    elsif type.blank? then
      return "Please submit the 'schemetype': /countrycode/type."
    else
      return Calcscheme.new.load(countrycode, type)
    end
  end
  def check_scheme(definition, scheme, version)
    if scheme.blank? then
      return "Please submit parameter 'scheme'."
    elsif version.blank? then
      return "Please submit the 'version': /countrycode/type/scheme/version."
    else
      return definition.set(scheme, version)
    end
  end
  def check_metaschemetype(countrycode, type)
    if countrycode.blank? then
      return "Please submit parameter 'countrycode'."
    elsif type.blank? then
      return "Please submit the 'metaschemetype': /countrycode/type."
    else
      return Calcscheme.new.meta_load(countrycode, type)
    end
  end
end
