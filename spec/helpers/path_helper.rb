module PathHelper
  def tmp_path
    File.expand_path("../../../tmp", __FILE__)
  end
end
