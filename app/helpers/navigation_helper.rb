module NavigationHelper
  def nav_link_classes(path)
    base = "block rounded-lg px-3 py-2 text-sm font-medium transition"

    if current_page?(path)
      "#{base} bg-gray-100 text-gray-900"
    else
      "#{base} text-gray-700 hover:bg-gray-100"
    end
  end
end
