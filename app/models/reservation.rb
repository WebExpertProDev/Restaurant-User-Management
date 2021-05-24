# DEPRECATED
# No longer saving reservations on our side. Pull directly from partners as needed
class Reservation < ApplicationRecord
  CONFIRMATION_ID_LENGTH = 15

  class << self
    def user_reservations(user_id:)
      Reservation.where(user_id: user_id)
    end

    def from_reservation!(user:, partner:, partner_reservation_details:, reservation_date:, cover:)
      Reservation.create(
        user_id: user.id,
        partner: partner,
        partner_reservation_details: partner_reservation_details,
        reservation_date: reservation_date.to_datetime,
        cover: cover,
        is_past: false,
        confirmation_id: generate_confirmation_id(),
      )
    end

    def generate_confirmation_id()
      charset = Array('A'..'Z') + Array(0..9)
      Array.new(CONFIRMATION_ID_LENGTH) { charset.sample }.join
    end

  end
end
