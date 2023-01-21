class Persistaccount < ApplicationRecord
  has_many :api_keys, as: :bearer 
  # Secure password adds functionality .authenticate(password) to the model which returns the Persistaccount if good and :false if bad.
  has_secure_password
end