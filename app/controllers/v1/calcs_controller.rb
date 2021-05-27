class V1::CalcsController < ApplicationController
  def discount
    render json: params
  end
end
