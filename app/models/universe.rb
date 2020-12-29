class Universe < ApplicationRecord
	validates :displaysymbol, presence: true
	has_many :optionchains
end
