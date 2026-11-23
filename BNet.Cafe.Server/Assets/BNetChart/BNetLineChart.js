// =============================================================================
// BNet Line Chart Component (same options as before)
// =============================================================================
class BNetLineChart extends BNetBaseChart {
    constructor(options) {
        super(options);
        this.viewBox = options.viewBox || "0 0 600 240";
        this.width = options.width || 600;
        this.height = options.height || 240;
        this.xKey = options.xKey || 'date';
        this.yKey = options.yKey || 'amount';
        this.currencySymbol = options.currencySymbol !== undefined ? options.currencySymbol : "₱";
        this.strokeColor = options.strokeColor || "var(--primary)";
        this.render();
    }

    // Smooth curve that never overshoots the data (monotone cubic)
    smoothPath(pts) {
        const n = pts.length;
        if (n < 3) return pts.map((q, i) => `${i ? 'L' : 'M'} ${q.x} ${q.y}`).join(' ');
        const dx = [], m = [], t = [];
        for (let i = 0; i < n - 1; i++) {
            dx[i] = pts[i + 1].x - pts[i].x;
            m[i] = (pts[i + 1].y - pts[i].y) / dx[i];
        }
        t[0] = m[0];
        t[n - 1] = m[n - 2];
        for (let i = 1; i < n - 1; i++) t[i] = m[i - 1] * m[i] <= 0 ? 0 : (m[i - 1] + m[i]) / 2;
        for (let i = 0; i < n - 1; i++) {
            if (m[i] === 0) { t[i] = 0; t[i + 1] = 0; continue; }
            const a = t[i] / m[i], b = t[i + 1] / m[i], s = a * a + b * b;
            if (s > 9) {
                const k = 3 / Math.sqrt(s);
                t[i] = k * a * m[i];
                t[i + 1] = k * b * m[i];
            }
        }
        let d = `M ${pts[0].x} ${pts[0].y}`;
        for (let i = 0; i < n - 1; i++) {
            const h = dx[i] / 3;
            d += ` C ${pts[i].x + h} ${pts[i].y + t[i] * h} ${pts[i + 1].x - h} ${pts[i + 1].y - t[i + 1] * h} ${pts[i + 1].x} ${pts[i + 1].y}`;
        }
        return d;
    }

    render() {
        this.initSVG();
        const yk = this.yKey, xk = this.xKey;
        const total = this.data.reduce((acc, item) => acc + (item[yk] || 0), 0);
        if (!this.data.length || total <= 0) {
            this.renderEmpty(this.width, this.height);
            return;
        }

        const p = this.pad;
        const n = this.data.length;
        const innerW = this.width - p.left - p.right;
        const innerH = this.height - p.top - p.bottom;
        const baseY = p.top + innerH;
        const scale = this.niceScale(Math.max(...this.data.map(d => d[yk] || 0)));
        const animate = !this._rendered;
        const cs = this.currencySymbol;

        const points = this.data.map((d, i) => ({
            x: n > 1 ? p.left + (i / (n - 1)) * innerW : p.left + innerW / 2,
            y: baseY - ((d[yk] || 0) / scale.max) * innerH,
            data: d
        }));

        // Gradient under the line
        const gid = `bnet-grad-${this.uid}`;
        const defs = this.el("defs");
        const grad = this.el("linearGradient", { id: gid, x1: "0", y1: "0", x2: "0", y2: "1" }, defs);
        this.el("stop", { offset: "0%", style: `stop-color:${this.strokeColor};stop-opacity:0.28` }, grad);
        this.el("stop", { offset: "100%", style: `stop-color:${this.strokeColor};stop-opacity:0` }, grad);

        // Gridlines + Y labels
        for (let i = 0; i <= scale.count; i++) {
            const y = baseY - (i / scale.count) * innerH;
            this.el("line", {
                x1: p.left, y1: y, x2: this.width - p.right, y2: y,
                stroke: "var(--border-light)",
                "stroke-dasharray": i === 0 ? "0" : "3 4"
            });
            this.text(p.left - 8, y + 3.5, `${cs}${this.formatCompact(scale.step * i)}`, {
                "text-anchor": "end", "font-size": "10"
            });
        }

        // Area + line
        const line = this.smoothPath(points);
        if (n > 1) {
            const first = points[0], last = points[n - 1];
            this.el("path", {
                d: `${line} L ${last.x} ${baseY} L ${first.x} ${baseY} Z`,
                fill: `url(#${gid})`, stroke: "none",
                class: "bnet-area" + (animate ? " bnet-animate" : "")
            });
        }
        this.el("path", {
            d: line, fill: "none", stroke: this.strokeColor, "stroke-width": "2.5",
            "stroke-linecap": "round", "stroke-linejoin": "round", pathLength: "1",
            class: "bnet-line" + (animate ? " bnet-animate" : "")
        });

        // Hover guide
        const guide = this.el("line", {
            y1: p.top, y2: baseY, stroke: "var(--text-light-secondary)",
            "stroke-dasharray": "3 3", "stroke-width": "1", opacity: "0", class: "bnet-guide"
        });

        // Points, labels, hit areas
        const labelStep = Math.max(1, Math.ceil(n / Math.max(1, Math.floor(innerW / 60))));
        const showDots = n <= 24;

        points.forEach((pt, i) => {
            const dot = this.el("circle", {
                cx: pt.x, cy: pt.y, r: 3.5,
                fill: this.strokeColor, stroke: "var(--bg-light-secondary, #fff)", "stroke-width": "2",
                class: "bnet-dot", opacity: showDots ? "1" : "0"
            });

            if (i % labelStep === 0) {
                this.text(pt.x, this.height - p.bottom + 18, pt.data[xk], { "font-size": "11" });
            }

            const hit = this.el("circle", { cx: pt.x, cy: pt.y, r: 14, fill: "transparent", class: "bnet-hit" });
            hit.style.cursor = "pointer";
            this.bindTooltip(hit, () => {
                const raw = pt.data[yk];
                const val = typeof raw === 'number' ? raw.toFixed(2) : raw;
                return `${pt.data[xk]}: ${cs}${val}`;
            }, {
                enter: () => {
                    guide.setAttribute("x1", pt.x);
                    guide.setAttribute("x2", pt.x);
                    guide.setAttribute("opacity", "0.6");
                    dot.setAttribute("r", 5.5);
                    dot.setAttribute("opacity", "1");
                },
                leave: () => {
                    guide.setAttribute("opacity", "0");
                    dot.setAttribute("r", 3.5);
                    dot.setAttribute("opacity", showDots ? "1" : "0");
                }
            });
        });

        this._rendered = true;
    }
}