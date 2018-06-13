Dir[File.join(".", "lib/*.rb")].each { |f| require f }


# if Time.now.day == 28
#   move_files_2_dropbox("charts")
#   move_files_2_dropbox("csv")
# end

# move_files_2_dropbox_in_daily_folder("charts")

fm = Dropbox::FileMover.new
