class V1::CsadminController < ApplicationController
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
