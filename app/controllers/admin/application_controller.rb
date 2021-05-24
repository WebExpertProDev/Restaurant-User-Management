# frozen_string_literal: true

# A lightweight, feature incomplete, soon-to-be-replaced implementation of the json-server
# protocol for Rails. Just being used to port the admin over quickly.
# TODO: convert to JSON-API.
class Admin::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    builder = model.select("*")

    builder = builder.limit(params[:_end].to_i - params[:_start].to_i).offset(params[:_start]) if params.include?(:_start) && params.include?(:_end)
    builder = add_order_constraints(builder, params[:_sort], params[:_order] || "asc") if params[:_sort]

    rows = builder.all

    {
      'X-Total-Count': model.count,
      'Access-Control-Expose-Headers': "X-Total-Count",
    }.each do |(key, val)|
      response.set_header(key.to_s, val)
    end

    render json: rows.map { |row| serialize(row) }
  end

  def show
    render json: serialize(model.find(params[:id]))
  end

  def update
    obj = model.find(params[:id])
    obj.update attributes_to_update

    render json: serialize(obj)
  end

  private

  def model
    throw "Please implement model method"
  end

  def serialize(obj)
    throw "Please implement serialize method"
  end

  def attributes
    throw "Please implement the attributes method"
  end

  def attributes_to_create
    attributes
  end

  def attributes_to_update
    attributes
  end

  def require_admin!
    head :forbidden unless current_user.is_admin
  end

  def add_order_constraints(builder, sort_column, order)
    unless sort_column.index(".").nil?
      sort_columns = sort_column.split(".")
      pg_column = sort_columns.first
      json_columns = sort_columns.slice(1, sort_columns.count).map { |col| "'#{col}'" }
      sort_column = "#{pg_column}->>#{json_columns.join("->")}"
    end

    builder.order("#{sort_column} #{(order || "asc").upcase === "DESC" ? "DESC" : "ASC"}")
  end
end
