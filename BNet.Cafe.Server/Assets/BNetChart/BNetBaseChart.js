// =============================================================================
// BNet Core Base Chart Class (Responsive + Touch friendly)
// Same constructor options as before. New optional: responsive (default true).
// When no fixed `width` is passed, the chart measures its container and
// re-renders on resize, so text stays crisp and readable on phones.
// =============================================================================
class BNetBaseChart {
    constructor(options) {
        this.container = typeof options.container === 'string'
            ? document.querySelector(options.container)
            : options.container;
        this.data = options.data || [];
        this.customPadding = options.padding || null;   // uniform padding, only if passed
        this.viewBox = options.viewBox || "0 0 600 240";
        this._autoWidth = options.width === undefined && options.responsive !== false;
        BNetBaseChart._uid = (BNetBaseChart._uid || 0) + 1;
        this.uid = BNetBaseChart._uid;
        this.tooltip = this.getOrCreateTooltip();
        this.svg = null;
        this._rendered = false;
        this._observer = null;
        this._lastW = 0;
    }

    // ---------- Layout ----------
    get pad() {
        if (this.customPadding) {
            const p = this.customPadding;
            return { top: p, right: p, bottom: p, left: p };
        }
        const narrow = (this.width || 600) < 480;
        return {
            top: 16,
            right: narrow ? 12 : 20,
            bottom: narrow ? 28 : 32,
            left: narrow ? 36 : 44
        };
    }

    _measure() {
        const host = this.container;
        const w = Math.round(host.clientWidth || host.getBoundingClientRect().width || 0);
        if (w > 0) {
            this.width = Math.max(260, w);
            this.viewBox = `0 0 ${this.width} ${this.height}`;
        }
    }

    _observe() {
        if (this._observer || !this._autoWidth || typeof ResizeObserver === 'undefined') return;
        const isSvg = this.container.tagName && this.container.tagName.toLowerCase() === 'svg';
        const target = isSvg ? (this.container.parentElement || this.container) : this.container;
        this._lastW = Math.round(target.clientWidth);
        this._observer = new ResizeObserver(() => {
            const w = Math.round(target.clientWidth);
            if (!w || Math.abs(w - this._lastW) < 4) return;
            this._lastW = w;
            clearTimeout(this._resizeTimer);
            this._resizeTimer = setTimeout(() => this.render(), 120);
        });
        this._observer.observe(target);
    }

    destroy() {
        if (this._observer) this._observer.disconnect();
        this._observer = null;
        this.hideTooltip();
    }

    initSVG() {
        if (!this.container) return;
        if (this._autoWidth && this.height) this._measure();

        if (this.container.tagName && this.container.tagName.toLowerCase() === 'svg') {
            this.svg = this.container;
            this.svg.innerHTML = '';
        } else {
            this.container.innerHTML = '';
            this.svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
            this.container.appendChild(this.svg);
        }

        this.svg.setAttribute("viewBox", this.viewBox);
        this.svg.setAttribute("preserveAspectRatio", "xMidYMid meet");
        this.svg.setAttribute("role", "img");
        this.svg.style.width = "100%";
        this.svg.style.height = "100%";
        this._observe();
    }

    // ---------- SVG helpers ----------
    el(tag, attrs = {}, parent = this.svg) {
        const node = document.createElementNS("http://www.w3.org/2000/svg", tag);
        Object.keys(attrs).forEach(k => node.setAttribute(k, attrs[k]));
        if (parent) parent.appendChild(node);
        return node;
    }

    text(x, y, content, attrs = {}) {
        const t = this.el("text", Object.assign({
            x, y, "text-anchor": "middle", fill: "var(--text-light-secondary)", "font-size": "11"
        }, attrs));
        t.textContent = content;
        return t;
    }

    // Rounds the axis maximum up to a clean value (e.g. 10, 20, 50, 100)
    niceScale(maxVal, count = 4) {
        if (!(maxVal > 0)) return { max: count, step: 1, count };
        const rough = maxVal / count;
        const pow = Math.pow(10, Math.floor(Math.log10(rough)));
        const f = rough / pow;
        const nice = (f <= 1 ? 1 : f <= 2 ? 2 : f <= 5 ? 5 : 10) * pow;
        return { max: nice * count, step: nice, count };
    }

    formatCompact(n) {
        const a = Math.abs(n);
        if (a >= 1e9) return (n / 1e9).toFixed(1).replace(/\.0$/, '') + 'B';
        if (a >= 1e6) return (n / 1e6).toFixed(1).replace(/\.0$/, '') + 'M';
        if (a >= 1e4) return (n / 1e3).toFixed(1).replace(/\.0$/, '') + 'k';
        return Number.isInteger(n) ? String(n) : n.toFixed(1);
    }

    // ---------- Tooltip ----------
    getOrCreateTooltip() {
        let tooltip = document.getElementById("BNetChartTooltip");
        if (!tooltip) {
            tooltip = document.createElement("div");
            tooltip.id = "BNetChartTooltip";
            tooltip.className = "chart-tooltip";
            tooltip.setAttribute("role", "tooltip");
            document.body.appendChild(tooltip);
        }
        return tooltip;
    }

    showTooltip(evt, text) {
        if (!this.tooltip) return;
        const t = this.tooltip;
        t.textContent = text;
        t.style.opacity = "1";
        const gap = 12, w = t.offsetWidth, h = t.offsetHeight;
        let x = evt.clientX + gap;
        let y = evt.clientY - h - 10;
        if (x + w > window.innerWidth - 8) x = evt.clientX - w - gap;   // keep inside the screen
        if (x < 8) x = 8;
        if (y < 8) y = evt.clientY + 18;
        t.style.left = `${x}px`;
        t.style.top = `${y}px`;
    }

    hideTooltip() {
        if (this.tooltip) this.tooltip.style.opacity = "0";
    }

    // Mouse, pen and touch. Touch keeps the tooltip visible briefly after the tap.
    bindTooltip(node, getText, hooks = {}) {
        const show = (e) => {
            clearTimeout(this._hideTimer);
            this.showTooltip(e, typeof getText === 'function' ? getText() : getText);
            if (hooks.enter) hooks.enter(e);
        };
        const hide = () => {
            this.hideTooltip();
            if (hooks.leave) hooks.leave();
        };
        node.addEventListener("pointerenter", show);
        node.addEventListener("pointermove", show);
        node.addEventListener("pointerdown", show);
        node.addEventListener("pointerleave", (e) => { if (e.pointerType !== 'touch') hide(); });
        node.addEventListener("pointercancel", hide);
        node.addEventListener("pointerup", (e) => {
            if (e.pointerType === 'touch') {
                clearTimeout(this._hideTimer);
                this._hideTimer = setTimeout(hide, 1800);
            }
        });
    }

    // ---------- Empty state ----------
    renderEmpty(width = 600, height = 240) {
        if (!this.svg) return;
        this.svg.innerHTML = '';
        const cx = width / 2, cy = height / 2;
        const g = this.el("g", { opacity: "0.55" });
        // small bar-chart icon
        this.el("rect", { x: cx - 14, y: cy - 6, width: 6, height: 14, rx: 2, fill: "var(--text-light-secondary, #888)" }, g);
        this.el("rect", { x: cx - 3, y: cy - 16, width: 6, height: 24, rx: 2, fill: "var(--text-light-secondary, #888)" }, g);
        this.el("rect", { x: cx + 8, y: cy - 11, width: 6, height: 19, rx: 2, fill: "var(--text-light-secondary, #888)" }, g);
        this.text(cx, cy + 28, "No data available", {
            fill: "var(--text-light-secondary, #888)", "font-size": "13"
        });
    }

    updateData(newData) {
        this.data = newData;
        this.render();
    }

    render() {
        console.warn("render() must be implemented by subclass");
    }
}