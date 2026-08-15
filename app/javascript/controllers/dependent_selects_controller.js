import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["customer", "site", "asset"]

  connect() {
    this.filterSites()
  }

  customerChanged() {
    this.siteTarget.value = ""
    this.assetTarget.value = ""
    this.filterSites()
  }

  siteChanged() {
    this.assetTarget.value = ""
    this.filterAssets()
  }

  filterSites() {
    const customerId = this.customerTarget.value

    this.siteTarget.querySelectorAll("option").forEach((option) => {
      const visible = option.value === "" || option.dataset.customerId === customerId
      option.disabled = !visible
      option.hidden = !visible
    })

    if (this.siteTarget.selectedOptions[0]?.disabled) this.siteTarget.value = ""
    this.filterAssets()
  }

  filterAssets() {
    const siteId = this.siteTarget.value

    this.assetTarget.querySelectorAll("option").forEach((option) => {
      const visible = option.value === "" || option.dataset.siteId === siteId
      option.disabled = !visible
      option.hidden = !visible
    })

    if (this.assetTarget.selectedOptions[0]?.disabled) this.assetTarget.value = ""
  }
}
