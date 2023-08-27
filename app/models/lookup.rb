class Lookup
	include ActiveModel::Model
	attr_accessor :csvparsed 
	
	def readcsv(filename)
		filepath="jsonlib/"+filename+"csv"
		# Add an error catcher
		filestring = File.read(filepath)
		self.csvparsed = CSV.parse(filestring, :headers => true)
	end
	def find(argumenthash)
		
	end
end