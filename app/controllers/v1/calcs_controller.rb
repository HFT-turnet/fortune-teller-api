class V1::CalcsController < ApplicationController
  def tv_model
    tv=Timevalue.new
    tv.sv=100
    tv.interest=2
    render json: tv
  end

  def discount
    ts=Valueflow.new
    ts.r=0.02
    ts.getorcreate_tv_at_t(5)
    ts.tvs.first.sv=100
    ts.buildseries    
    render json: ts
  end
end
