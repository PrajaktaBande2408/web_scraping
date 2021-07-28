# frozen_string_literal: true

require 'fileutils'

# module for open/delete/write files
module FileHelper
  def open_file(target_path, file_name, mode)
    File.open(valid_target_path(target_path, file_name), mode)
  end

  def read_file(target_path, file_name)
    File.read(valid_target_path(target_path, file_name))
  end

  def delete_file(target_path, file_name)
    target_path = File.expand_path(target_path.to_s, File.dirname(__FILE__))
    target_path << "/#{file_name}"
    File.delete(target_path) if File.exist?(target_path)
  end

  def delete_dir(dir_path)
    dir_path = File.expand_path(dir_path.to_s, File.dirname(__FILE__))
    Dir.delete(dir_path) if Dir.exist?(dir_path)
  end

  def valid_target_path(target_path, file_name)
    target_path = File.expand_path(target_path.to_s, File.dirname(__FILE__))

    FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
    target_path << "/#{file_name}"
  end
end
