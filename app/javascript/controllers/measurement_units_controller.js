import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "unit"]

  connect() {
    this.filter()
  }

  change() {
    this.filter(true)
  }

  filter(reset = false) {
    const quantity = this.quantityTarget.value
    const options = Array.from(this.unitTarget.options)

    options.forEach((option) => {
      const visible = option.dataset.quantity === quantity
      option.hidden = !visible
      option.disabled = !visible
    })

    if (reset || this.unitTarget.selectedOptions[0]?.disabled) {
      const first = options.find((option) => !option.disabled)
      if (first) this.unitTarget.value = first.value
    }
  }
}
