module Response
  def json_response(object, status = :ok)
    render json: object, status: status
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def ok_response
    head(:ok)
  end
end
