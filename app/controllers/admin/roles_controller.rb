class Admin::RolesController < Admin::BaseController
  before_action :require_super_admin!

  def index
    @admin_users = User.joins(:roles)
                        .where(roles: { name: %w[super_admin accountant] })
                        .distinct
                        .order(:phone)
  end
end
