import { Controller } from "@hotwired/stimulus"

// Search-as-you-type for the Position form: queries /market_data/search and
// fills the name/ticker fields when a result is picked.
export default class extends Controller {
  static targets = ["input", "ticker", "results"]
  static values = { url: String }

  connect() {
    this.debounceTimer = null
    this.results = []
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
  }

  search() {
    clearTimeout(this.debounceTimer)
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      this.clear()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchResults(query), 300)
  }

  hideDelayed() {
    // Delay so a click on a result registers before blur removes it.
    setTimeout(() => this.clear(), 150)
  }

  async fetchResults(query) {
    const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
      headers: { Accept: "application/json" }
    })

    if (!response.ok) {
      this.clear()
      return
    }

    this.render(await response.json())
  }

  render(results) {
    this.results = results

    if (results.length === 0) {
      this.clear()
      return
    }

    this.resultsTarget.innerHTML = results
      .map((result, index) => `
        <button type="button" class="asset-search__option" data-index="${index}" data-action="asset-search#pick">
          <span class="asset-search__name">${this.escape(result.name)}</span>
          <span class="asset-search__meta">${this.escape(result.ticker)}${result.exchange ? ` · ${this.escape(result.exchange)}` : ""}</span>
        </button>
      `)
      .join("")

    this.resultsTarget.hidden = false
  }

  pick(event) {
    const result = this.results[event.currentTarget.dataset.index]
    if (!result) return

    this.inputTarget.value = result.name
    if (this.hasTickerTarget) this.tickerTarget.value = result.ticker
    this.clear()
  }

  clear() {
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.hidden = true
  }

  escape(value) {
    const div = document.createElement("div")
    div.textContent = value || ""
    return div.innerHTML
  }
}
