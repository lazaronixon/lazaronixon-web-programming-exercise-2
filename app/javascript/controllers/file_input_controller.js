import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "input", "filename" ]

  update() {
    this.filenameTarget.textContent = this.inputTarget.files[0].name
  }
}
