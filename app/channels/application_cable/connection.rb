module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    protected

    def find_verified_user
      if verified_user = env['warden'].user
        verified_user
      else
        # Allow guest users for the voice assistant for now, or reject them
        # reject_unauthorized_connection
        nil
      end
    end
  end
end
