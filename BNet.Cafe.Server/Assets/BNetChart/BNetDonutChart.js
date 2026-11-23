// =============================================================================
// BNet Donut Chart Component (same options as before)
// =============================================================================
class BNetDonutChart extends BNetBaseChart {
    constructor(options) {
        super(options);
        this.viewBox = options.viewBox || "0 0 200 200";
        this.radius = options.radius || 65;
        this.cx = options.cx || 100;
        this.cy = options.cy || 100;
        this.labelKey = options.labelKey || 'label';
        this.valueKey = options.valueKey || 'value';
        this.colorKey = options.colorKey || 'color';
        this.onLegendUpdate = options.onLegendUpdate || null;
        this.render();
    }

    render() {
        this.initSVG();
        const vk = this.valueKey, lk = this.labelKey;
        const total = this.data.reduce((acc, item) => acc + (item[vk] || 0), 0);

        if (total <= 0) {
            this.renderEmpty(200, 200);
            return;
        }

        const animate = !this._rendered;
        const visible = this.data.filter(d => (d[vk] || 0) > 0);
        const gap = visible.length > 1 ? 2 : 0;        // small gap (degrees) between segments

        // Background ring
        this.el("circle", {
            cx: this.cx, cy: this.cy, r: this.radius, fill: "none",
            stroke: "var(--bg-light-tertiary, #e5e7eb)", "stroke-width": "20"
        });

        let accumulated = 0;
        visible.forEach((item, idx) => {
            const val = item[vk];
            const angle = (val / total) * 360;
            let start = accumulated;
            let end = accumulated + angle;
            accumulated += angle;

            if (gap && angle > gap * 2) {
                start += gap / 2;
                end -= gap / 2;
            }
            const effectiveEnd = end - start >= 360 ? start + 359.999 : end;

            const rad = a => Math.PI * (a - 90) / 180;
            const x1 = this.cx + this.radius * Math.cos(rad(start));
            const y1 = this.cy + this.radius * Math.sin(rad(start));
            const x2 = this.cx + this.radius * Math.cos(rad(effectiveEnd));
            const y2 = this.cy + this.radius * Math.sin(rad(effectiveEnd));
            const large = (effectiveEnd - start) > 180 ? 1 : 0;

            const path = this.el("path", {
                d: `M ${x1} ${y1} A ${this.radius} ${this.radius} 0 ${large} 1 ${x2} ${y2}`,
                fill: "none",
                stroke: item[this.colorKey] || "#3b82f6",
                "stroke-width": "20",
                "stroke-linecap": "butt",
                class: "donut-segment" + (animate ? " bnet-animate" : "")
            });
            path.style.setProperty("--i", idx);

            this.bindTooltip(path, `${item[lk]}: ${val} (${((val / total) * 100).toFixed(1)}%)`);
        });

        // Center total
        const label = String(total);
        this.text(this.cx, this.cy + 3, label, {
            fill: "var(--text-light, #333)",
            "font-size": label.length > 7 ? "15" : label.length > 5 ? "18" : "22",
            "font-weight": "700"
        });
        this.text(this.cx, this.cy + 17, "Total", { "font-size": "9" });

        this._rendered = true;

        if (typeof this.onLegendUpdate === 'function') {
            this.onLegendUpdate(this.data, total);
        }
    }
}