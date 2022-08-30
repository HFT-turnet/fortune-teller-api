class V1::SchemeController < ApplicationController
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
  
  def runscheme
    # Expects params. These include the scheme, the calculation and version (if existent)
    # Also include post-payload for the required calculation
    
    # if param[:debug] is set, then instead of result the debuglog is parsed back.
    
    # Check all required params are there
    if params[:countrycode].blank? then
      render json: "Please submit parameter 'countrycode'."
    end
    
    # Initialize the Scheme
    
    # Check inputs for Scheme are there.
    
    # Run Scheme
    
    # Feedback results, disclaimer and any error messages along the way
    
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
  
end
