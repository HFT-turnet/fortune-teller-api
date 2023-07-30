class V1::CsController < ApplicationController
  #controller=V1::SchemeController.new
  #controller.income
  
  def test
    puts "Hallo"
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
      render json: check1
      return
    end
    
    # Initialize the definition
    definition=Calcscheme.new
    definition.load(params[:countrycode], params[:schemetype])
    # Check all required scheme-level params are there
    check2=check_scheme(definition, params[:scheme], params[:version])
    puts definition
    unless check2=="OK"
      render json: check2
      return # or should we continue
    end
    
    # Convert parameters to input
    inputs={}
    params[:c].each { |key,value| inputs[key]=value }
    
    # Run Scheme, this automatically checks whether necessary inputs have been provided.
    check3=definition.run(inputs)
    unless check3=="OK"
      render json: check3
      return 
    end
    
    # Feedback results, disclaimer and any error messages along the way
    render json: definition.result
  end
  
  def runmetascheme
    # Expects params. These include the scheme, the calculation and version (if existent)
    # Also include post-payload for the required calculation
    
    # Check all required params are there
    if params[:countrycode].blank? then
      render json: "Please submit parameter 'countrycode'."
    end
    
    # Initialize the Scheme
    
    # Check inputs for Scheme are there.
    
    # Run Scheme
    
    # Feedback results, disclaimer and any error messages along the way  
  end
  
  private
  def check_schemetype(countrycode, type)
    if countrycode.blank? then
      return "Please submit parameter 'countrycode'."
    elsif type.blank? then
      return "Please submit the 'scheme': /countrycode/type."
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
  
end
