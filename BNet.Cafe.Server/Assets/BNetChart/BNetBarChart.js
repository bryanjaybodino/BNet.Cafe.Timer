// =============================================================================
// BNet Bar Chart Component (same options as before)
// =============================================================================
class BNetBarChart extends BNetBaseChart {
    constructor(options) {
        super(options);
        this.viewBox = options.viewBox || "0 0 800 240";
        this.width = options.width || 800;
        this.height = options.height || 240;
        this.labelKey = options.labelKey || 'pc';
        this.valueKey = options.valueKey || 'count';
        this.barColor = options.barColor || "var(--secondary)";
        this.unitLabel = options.unitLabel || "rentals";
        this.render();
    }

    render() {
        this.initSVG();
        const vk = this.valueKey, lk = this.labelKey;
        const totalCount = this.data.reduce((acc, item) => acc + (item[vk] || 0), 0);
        if (!this.data.length || totalCount <= 0) {
            this.renderEmpty(this.width, this.height);
            return;
        }

        const p = this.pad;
        const n = this.data.length;
        const innerW = this.width - p.left - p.right;
        const innerH = this.height - p.top - p.bottom;
        const baseY = p.top + innerH;
        const scale = this.niceScale(Math.max(...this.data.map(d => d[vk] || 0)));
        const band = innerW / n;
        const barW = Math.max(4, Math.min(48, band * 0.62));
        const animate = !this._rendered;

        // Gridlines + Y labels
        for (let i = 0; i <= scale.count; i++) {
            const y = baseY - (i / scale.count) * innerH;
            this.el("line", {
                x1: p.left, y1: y, x2: this.width - p.right, y2: y,
                stroke: "var(--border-light)",
                "stroke-dasharray": i === 0 ? "0" : "3 4",
                "stroke-width": "1"
            });
            this.text(p.left - 8, y + 3.5, this.formatCompact(scale.step * i), {
                "text-anchor": "end", "font-size": "10"
            });
        }

        // Show every Nth x label so they never overlap
        const labelStep = Math.max(1, Math.ceil(n / Math.max(1, Math.floor(innerW / 46))));
        const maxChars = Math.max(3, Math.floor(band * labelStep / 6.5));
        const showValues = barW >= 20 && band >= 30;

        this.data.forEach((item, i) => {
            const val = item[vk] || 0;
            const x = p.left + i * band + (band - barW) / 2;
            const barH = Math.max(0, (val / scale.max) * innerH);
            const y = baseY - barH;

            const rect = this.el("rect", {
                x, y, width: barW, height: barH, rx: Math.min(5, barW / 2),
                fill: this.barColor,
                class: "bnet-bar" + (animate ? " bnet-animate" : "")
            });
            rect.style.setProperty("--i", i);

            if (i % labelStep === 0) {
                let label = String(item[lk] ?? '');
                if (label.length > maxChars) label = label.slice(0, maxChars - 1) + "…";
                this.text(x + barW / 2, this.height - p.bottom + 18, label, { "font-size": "11" });
            }

            if (showValues && val > 0) {
                this.text(x + barW / 2, y - 6, this.formatCompact(val), {
                    fill: "var(--text-light)", "font-size": "11", "font-weight": "600"
                });
            }

            // Full-height transparent hit area: easy to hover and tap
            const hit = this.el("rect", {
                x: p.left + i * band, y: p.top, width: band, height: innerH,
                fill: "transparent", class: "bnet-hit"
            });
            this.bindTooltip(hit, `${item[lk]}: ${val} ${this.unitLabel}`, {
                enter: () => rect.classList.add("is-active"),
                leave: () => rect.classList.remove("is-active")
            });
        });

        this._rendered = true;
    }
}