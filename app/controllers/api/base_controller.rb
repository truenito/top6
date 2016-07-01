module Api
  class BaseController < ApplicationController
    protect_from_forgery with :null_session
    before_action :set_resource, only: [:show, :update]
    respond_to :json

    private

    # Returns the requested resource from instance variable.
    def get_resource
      instance_variable_get("@#{resource_name}")
    end

    # Returns the allowed parameters for each collecion.
    # (override this method in each controller to permit additional searches)
    def query_params
      {}
    end

    # Returns allowed pagination params.
    def page_params
      params.permit(:page, :page_size)
    end

    # Returns the class of requested resource base on the controller.
    def resource_name
      @resource_name ||= self.controller_name.singularize
    end
  end
end
