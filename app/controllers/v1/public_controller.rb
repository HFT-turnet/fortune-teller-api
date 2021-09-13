class V1::PublicController < ApplicationController
  #controller=V1::PublicController.new
  #controller.test
  
  # Base math (Single Value functions)
  def interest
    # params: targetyear
  end

  # Work with TIMESLICES (as in timeslize model)
    # Timeslices are driven by spending and time-morph by inclusion / exclusion and inflation
  def timeslize_get
    
    # Problem: Model-Instanz = führt zu demselben Model, nicht einer zweiten kopie davon
    
    # params: targetyear & Json-Load as Post
    # Instantiate Header as per JSON
    ts=Timeslice.new(timeslize_head_params)
    # Load named TVs into Timeslize
    ts.tvs_attributes=timeslize_tvs_params

    # Instantiate Target instancee
    getslize=ts

    # Run Targetyear transformation
    getslize.slice_at(params[:targetyear])
    # Find Total Sums
    p ts.ctosum
    p getslize.ctosum
    # Prepare Render
    
    render json: getslize
  end
  
  def timeslize_series
    # Turn timeslize into series with interval
    # params: interval
    
  end
  
  # Work with VALUEFLOWS (as in valueflows model). Includes Financial Assets and Debt Outlook
    # Valueflows are driven by contracts, the financial market or do not change
  def test
    puts "Hallo"
  end
  
  # Work with Calculation Models
  
  # Params definition
  
  def timeslize_head_params
    #params.require(:tvs).permit!
    params[:public].permit(:t,:i,:tvs)
  end
  def timeslize_tvs_params
    #params.require(:tvs).permit!
    params[:public].permit(tvs: [
     :label,
     :cto, 
     :fromt,
     :tot, 
     :inflation]
     ).require(:tvs)#.permit(:sv, :tax, :fee, :interest, :valuation, :cto, :t, :ev)
  end
  
    
end
