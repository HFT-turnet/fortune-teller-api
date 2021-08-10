class V1::CalcsController < ApplicationController
  def readjson
    file = File.read('jsonlib/DE.json')
    data_hash = JSON.parse(file)
    File.write('./sample-data.json', JSON.dump(data_hash))
  end
  
  
  def tv_model
    ts=Valueflow.new
    ts.r=3
    ts.from=nil
    ts.to=nil
    ts.getorcreate_tv_at_t(0)
    ts.getorcreate_tv_at_t(1)
    ts.tvs.first.sv=101
    render json: ts.as_json
  end
  
  def ts_model
    tv=Timevalue.new
    tv.sv=100
    tv.interest=2
    render json: tv
  end
  
  def tv_get
    # TV Get only knows two periods in the model: 0 and 1, the number of periods to be discounted is in the header
    # Set the Header and initiate
    ts=Valueflow.new(tshead_params)
    # Set t=0 data
    ts.tvs.first.update(tvs_params[0])
    # Create t=1 dataset
    ts.getorcreate_tv_at_t(1)
    ts.tvs.last.update(tvs_params[1])
    # Call TV calculation
    ts.setTwoPeriodEv
    # Play back the dataset
    render json: ts.as_json
  end

  def discount
    ts=Valueflow.new
    ts.r=0.02
    ts.getorcreate_tv_at_t(5)
    ts.tvs.first.sv=100
    ts.tvs.first.sv=100
    ts.buildseries 
    #p ts
    #p ts.as_json   
    render json: ts.as_json
  end
end

## Add attributes_check

def tshead_params
  #params.require(:tvs).permit!
  params.permit(:r,:from,:to,:periods,:tvs)
end
def tvs_params
  #params.require(:tvs).permit!
  params.permit(tvs: [
   :sv,
   :tax, 
   :fee, 
   :interest, 
   :valuation, 
   :cto, 
   :t, 
   :ev]
   ).require(:tvs)#.permit(:sv, :tax, :fee, :interest, :valuation, :cto, :t, :ev)
end
