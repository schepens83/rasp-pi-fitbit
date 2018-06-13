require "./lib/dropbox.rb"

fm = Dropbox::FileMover.new

if Time.now.day == 28
  fm.move_files_to("charts")
  fm.move_files_to("csv")
end

fm.move_files_to_daily("charts")
