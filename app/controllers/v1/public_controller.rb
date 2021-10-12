class V1::PublicController < ApplicationController
  #controller=V1::PublicController.new
  #controller.test
  
  # Base math (Single Value functions)
  # tbd
  
  # Transformations
    # Use Timevalue Models for transformations
  def timemorph
    # Inflation and Deflation
    #information = request.raw_post
    data_parsed = JSON.parse(request.raw_post)
    #p data_parsed
    jsonout=[]
    data_parsed.each do |json|
      ts=Valueflow.new(json)
      ts.tvs=[]
      ts.tvs_attributes=json["tvs"]
  # OPEN: include check whether the relevant fields are available
      ts.twoperiodcomplete
      jsonout << ts.as_json
    end
    render json: jsonout
  end

  # Work with TIMESLICES (as in timeslize model)
    # Timeslices are driven by spending and time-morph by inclusion / exclusion and inflation
  
  def timeslice_sample
    # Get request to get a timeslize JSON without values

    # Instantiate Header as per JSON
    sample=Timeslice.new
    sample.i=0.02
    sample.t=0
    # Load sample TVs into Timeslize
    entries=[]
    
    if params[:type]=="income" then
      entries.push({"label"=>"Income","cto"=>"0","fromt"=>"0","tot"=>"2000"})
    end
    
    if params[:type]=="expense" then
      entries.push({"label"=>"Miete und Nebenkosten","cto"=>"0","fromt"=>"0","tot"=>"2000"}) #    Wohnung, Wasser, Strom, Gas	4	1,8%
      entries.push({"label"=>"Verpflegung","cto"=>"0","fromt"=>"0","tot"=>"2000"})   #    Nahrungsmittel und alkoholfreie Getränke	1	1,1%   #    Alkoholische Getränke & Tabak	2	2,5%


      entries.push({"label"=>"Transport (KFZ, Öffis)","cto"=>"0","fromt"=>"0","tot"=>"2000"})
      entries.push({"label"=>"Anschaffungen (Kleidung, Wohnausstattg)","cto"=>"0","fromt"=>"0","tot"=>"2000"}) #    Bekleidung & Schuhe	3	1,4% #    Möbel, Leuchten, Geräte, anderes Haushaltszubehör	5	0,8%
      entries.push({"label"=>"Kommunikation (Internet, Handy...)","cto"=>"0","fromt"=>"0","tot"=>"2000"})   #    Post und Telekommunilkation	8	-0,7%

      entries.push({"label"=>"Dienstleistungen","cto"=>"0","fromt"=>"0","tot"=>"2000"})
      entries.push({"label"=>"Sport und Hobby","cto"=>"0","fromt"=>"0","tot"=>"2000"})
      entries.push({"label"=>"Urlaub","cto"=>"0","fromt"=>"0","tot"=>"2000"})
      entries.push({"label"=>"Versicherungen","cto"=>"0","fromt"=>"0","tot"=>"2000"})
      entries.push({"label"=>"Bildung","cto"=>"0","fromt"=>"0","tot"=>"2000"})   #    Bildungswesen	10	-0,3%
      
    end
    
#    Inflationslabel	Abteilung	2019
#    Gesundheit	6	1,1%
#    Verkehr	7	1,2%
#    Freizeit, Unterhaltung, Kultur	9	0,6%
#    Gaststätten und Beherbergung	11	2,5%
#    Andere Waren und Dienstleistungen	12	2,2%   
    
    sample.tvs_attributes=entries
    render json: sample
  end
  
  def summary_report
    # Instantiate Header as per JSON
    @envelope=envelope_head
    expenses=Timeslice.new(envelope_expenses_head) unless params[:public][:expenses].blank?
    incomes=Timeslice.new(envelope_incomes_head) unless params[:public][:incomes].blank?

    # Load named TVs into Timeslice
    expenses.tvs_attributes=envelope_expenses_tvs unless params[:public][:expenses].blank?
    incomes.tvs_attributes=envelope_incomes_tvs unless params[:public][:incomes].blank?

# Add an info box that allows to review API comments
      # Backup (if needed: find a specific label in entries)
      #a=expenses.tvs.select {|tv| tv.label == e.label}
    
    # Expenses First
    # freeze function leads to a freeze of timevalues and considers limits (values set to zero if not in limit)    
    expenses_t0=expenses.freeze
    expenses_tf=expenses.move_to(40).freeze
    
    # Prepare for Json_parse
    @expenselist=[]
    expenses_t0.tvs.each_with_index do |t,i|
      @expenselist.push({"label"=>t.label,"cto_now"=>t.cto,"cto_then"=>expenses_tf[i].cto})
    end
    
    #p @expenselist
    
  unless incomes.blank?
  # Incomes Next (as above)
    incomes_t0=incomes.freeze
    incomes_tf=incomes.move_to(40).freeze 
  # Prepare for Json_parse
    @incomeslist=[]
    incomes_t0.tvs.each_with_index do |t,i|
      @incomeslist.push({"label"=>t.label,"cto_now"=>t.cto,"cto_then"=>@tfuture[i].cto})
    end
    #p @incomeslist
  end

  end
  
  def get_envelope
    # Instantiate Header as per JSON
    sample=Timeslice.new
    sample.i=0.02
    sample.t=2021
    render json: sample
  end
  
  def get_expenses

  end
  
  def get_incomes

  end
  
  def timeslice_sample2
    # Get request to get a timeslize JSON without values

    # Instantiate Header as per JSON
  #  sample=Timeslice.new
  #  sample.i=0.02
  #  sample.t=0
    # Load sample TVs into Timeslize
 #   entries=[]
#    entries.push({"label"=>"Miete und Nebenkosten","cto"=>"0","fromt"=>"0","tot"=>"2000"}) #    Wohnung, Wasser, Strom, Gas	4	1,8%
  #  entries.push({"label"=>"Verpflegung","cto"=>"0","fromt"=>"0","tot"=>"2000"})   #    Nahrungsmittel und alkoholfreie Getränke	1	1,1%   #    Alkoholische Getränke & Tabak	2	2,5%


  #  entries.push({"label"=>"Transport (KFZ, Öffis)","cto"=>"0","fromt"=>"0","tot"=>"2000"})
  #  entries.push({"label"=>"Anschaffungen (Kleidung, Wohnausstattg)","cto"=>"0","fromt"=>"0","tot"=>"2000"}) #    Bekleidung & Schuhe	3	1,4% #    Möbel, Leuchten, Geräte, anderes Haushaltszubehör	5	0,8%
#    entries.push({"label"=>"Kommunikation (Internet, Handy...)","cto"=>"0","fromt"=>"0","tot"=>"2000"})   #    Post und Telekommunilkation	8	-0,7%
    
#    Inflationslabel	Abteilung	2019
#    Gesundheit	6	1,1%
#    Verkehr	7	1,2%
#    Freizeit, Unterhaltung, Kultur	9	0,6%
#    Gaststätten und Beherbergung	11	2,5%
#    Andere Waren und Dienstleistungen	12	2,2%   
    
 #   sample.tvs_attributes=entries
     samplemodel='{
  "entries":
	{
	"positions":[
		{
		"label":"Netto-Einkommen",
		"cto_now":1000,
		"cto_then":0,
      	"positions":[
			{
      		"label":"Gehalt",
			"cto_now":1000,
			"cto_then":1500
			}
      	]
		},
		{
		"label":"Kosten",
      	"positions":[
			{
      		"label":"Essen",
			"cto_now":-1000,
			"cto_then":-1500
			},
			{
      		"label":"Reisen",
			"cto_now":-500,
			"cto_then":-1500
			}
      	]
		}
		]
	},
	"environment":
		{
			"year_now":"2020",
			"year_then":"2040"
		}
}'
    @list=[]
    @list << "eins"
    @list << "zwei"
    @list << "drei"
    p @list
    render json: samplemodel
  end
  
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
    jsonout=[]
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
          
      jsonout << output.as_json
    end
    
    render json: jsonout
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
    
    #p ts
    #ts.tvs.each do |tv|
    #  p tv.sv.to_s + " " +tv.fee.to_s+ " " +tv.valuation.to_s+ " " + tv.ev.to_s
    #end
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
  def envelope_head
    params[:public].permit(:from,:to)
  end
  def envelope_expenses_head
    params[:public][:expenses].permit(:t,:i,:tvs) 
  end
  def envelope_incomes_head
    params[:public][:incomes].permit(:t,:i,:tvs)
  end
  def envelope_expenses_tvs
    params[:public][:expenses].permit(tvs: [
     :label,
     :cto, 
     :fromt,
     :tot, 
     :inflation]
     ).require(:tvs)
  end
  def envelope_incomes_tvs
    params[:public][:incomes].permit(tvs: [
      :label,
      :cto, 
      :fromt,
      :tot, 
      :inflation]
      ).require(:tvs)
  end
  
end
