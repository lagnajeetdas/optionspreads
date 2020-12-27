class Recommendation < ApplicationRecord
	validates :symbol, presence: true
end
