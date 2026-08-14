// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "preline"

const initPreline = () => {
  if (window.HSStaticMethods && typeof window.HSStaticMethods.autoInit === "function") {
    window.HSStaticMethods.autoInit()
  }
}

document.addEventListener("turbo:load", initPreline)
document.addEventListener("turbo:frame-load", initPreline)
