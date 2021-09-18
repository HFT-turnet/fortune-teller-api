class V1::PublicController < ApplicationController
  #controller=V1::PublicController.new
  #controller.test
  
  # Base math (Single Value functions)
  # tbd
  
  # Transformations
    # Use Timevalue Models for transformations
  def inflate
  end
  
  def deflate
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
  
  def valueflow_complete
    # Get an incomplete valueflow and hand it back complete
    # Complete: in case of debt: EV=0
    
    # Params Interval accepted to limit feedback
    ts=Valueflow.new(valueflow_head_params)
    ts.tvs_attributes=valueflow_tvs_params
    ts.initialfix
    # Type dependent treatments
    ts.debtcalc if ts.type=="debt"
    ts.assetcalc if ts.type=="asset"
    
    p ts
    ts.tvs.each do |tv|
      p tv.sv.to_s + " " +tv.fee.to_s+ " " +tv.valuation.to_s+ " " + tv.ev.to_s
    end
    render json: ts
  end  
  
  def draft
    # TV Get only knows two periods in the model: 0 and 1, the number of periods to be discounted is in the header
    # Set the Header and initiate
    ts=Valueflow.new(valueflow_head_params)
    # Set t=0 data
    ts.tvs.first.update(valueflow_tvs_params[0])
    # Create t=1 dataset
    ts.getorcreate_tv_at_t(1)
    ts.tvs.last.update(valueflow_tvs_params[1])
    # Call TV calculation
    ts.setTwoPeriodEv
    # Play back the dataset
    render json: ts.as_json
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
  
  def valueflow_head_params
    #params.require(:tvs).permit!
    params[:public].permit(:label, :type, :r, :rm, :rf, :annuity,:from,:to,:periods,:tvs)
  end
  def valueflow_tvs_params
    #params.require(:tvs).permit!
    params[:public].permit(tvs: [
     :sv,
     :tax, 
     :fee, 
     :interest, 
     :valuation, 
     :cto, 
     :t, 
     :ev]
     ).require(:tvs)
  end
end
