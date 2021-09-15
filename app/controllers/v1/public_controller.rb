class V1::PublicController < ApplicationController
  #controller=V1::PublicController.new
  #controller.test
  
  # Base math (Single Value functions)
  def interest
    # params: targetyear
  end

  # Work with TIMESLICES (as in timeslize model)
    # Timeslices are driven by spending and time-morph by inclusion / exclusion and inflation
  
  def timeslice_get
    # params: targetyear & Json-Load as Post
    # Return: just converted timeslice

    # Instantiate Header as per JSON
    ts=Timeslice.new(timeslice_head_params)
    # Load named TVs into Timeslize
    ts.tvs_attributes=timeslice_tvs_params
    
    # Run Targetyear transformation
    ts.move_to(params[:targetyear])
    
    # Reduce tvs to those in the timeframe
    output=Timeslice.new
    output.t=ts.t
    output.i=ts.i
    output.tvs=ts.list
    
    render json: output
  end
  
  def timeslice_series
    # Turn timeslize into series with interval
    # params: targetyear
    # params: interval
    
    # Instantiate Header as per JSON
    ts=Timeslice.new(timeslice_head_params)

    # Load named TVs into Timeslize
    ts.tvs_attributes=timeslice_tvs_params
    
    # Instantiate Output
    json=[]
    #json << ts.as_json
    
    # Calc runs
    source_t=ts.t.to_i
    timeframe=params[:targetyear].to_i - source_t
    runs=(timeframe/params[:interval].to_i).ceil+1
    # Perform runs
    runs.times do |i|
      ts.move_to(source_t + params[:interval].to_i*(i)) unless i==0
      
      # Reduce tvs to those in the timeframe without deletion from original timeslice
      output=Timeslice.new
      output.t=ts.t
      output.i=ts.i
      output.tvs=ts.list
          
      json << output.as_json
    end
    
    render json: json
  end
  
  # Work with VALUEFLOWS (as in valueflows model). Includes Financial Assets and Debt Outlook
    # Valueflows are driven by contracts, the financial market or do not change
  def test
    puts "Hallo"
  end
  
  # Work with Calculation Models
  
  # Params definition
  
  def timeslice_head_params
    #params.require(:tvs).permit!
    params[:public].permit(:t,:i,:tvs)
  end
  def timeslice_tvs_params
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
