# A module that provides editor integration functionality for GemHadar.
#
# This module contains methods for determining the appropriate editor to use
# for interactive tasks, opening temporary files in editors for user modification,
# and editing specified files in an editor. It serves as a utility for
# automating text editing operations within the GemHadar framework.
#
# @example Finding and using an editor
#   editor = GemHadar::Editor.find_editor
#
# @example Editing a temporary file returning the changed content
#   content = "Initial content"
#   edited_content = GemHadar::Editor.edit_temp_file(content)
#
# @example Editing a specific file
#   GemHadar::Editor.edit_file('CHANGELOG.md')
module GemHadar::Editor
  # The find_editor method determines the appropriate editor to use for
  # interactive tasks.
  #
  # This method first checks the EDITOR environment variable for a custom
  # editor specification. If the environment variable is not set, it falls back
  # to using the vi editor by default. It then verifies that the identified
  # editor exists in the file system before returning it.
  #
  # @return [ String, nil ] the path to the editor command if found, or nil if
  #   the editor cannot be located
  # @return [ nil ] if the editor cannot be found in the file system
  def find_editor
    editor = ENV.fetch('EDITOR', `which vi`.chomp)
    unless File.exist?(editor)
      warn "Can't find EDITOR. => Returning."
      return
    end
    editor
  end

  # The edit_temp_file method opens a temporary file in an editor for user
  # modification.
  #
  # This method creates a temporary markdown file with the provided content,
  # opens it in the configured editor, waits for the user to finish editing,
  # and then reads the modified content back from the file.
  #
  # @param content [ String ] the initial content to write to the temporary file
  #
  # @return [ String ] the content of the file after editing, or nil if the editor
  #   could not be invoked or the file could not be read
  # @return [ nil ] if the editor could not be found or the operation was aborted
  def edit_temp_file(content)
    temp_file = Tempfile.new(%w[ changelog .md ])
    temp_file.write(content)
    temp_file.close

    edit_file(temp_file.path) or return

    File.read(temp_file.path)
  ensure
    temp_file&.close&.unlink
  end

  # The edit_file method opens a specified file in an editor for user
  # modification.
  #
  # This method retrieves the configured editor using find_editor, then invokes
  # the editor command with the provided filename as an argument. It waits for
  # the editor process to complete and returns true if successful, or false if
  # the editor command fails.
  #
  # @param filename [ String ] the path to the file to be opened in the editor
  #
  # @return [ true ] if the editor command executes successfully
  # @return [ false ] if the editor command fails or returns a non-zero exit status
  # @return [ nil ] if the editor cannot be found or the operation is aborted
  def edit_file(filename)
    editor = find_editor or return

    unless system("#{editor} #{filename}")
      warn "#{editor} returned #{$?.exitstatus} => Returning."
      return false
    end

    true
  end
end
