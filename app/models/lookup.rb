class Lookup
	require 'csv'
	include ActiveModel::Model
	attr_accessor :csvparsed 
	
	
	def readcsv(filename)
		filepath="jsonlib/"+filename+".csv"
		# Add an error catcher
		filestring = File.read(filepath)
		self.csvparsed = CSV.parse(filestring, :headers => true)
	end
	def find(argumenthash)
		b=a.csvparsed.select { |row| row['Geschlecht'] == 'm' && row[' Jahr']==" 2010"}
	end
end